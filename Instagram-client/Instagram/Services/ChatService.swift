//
//  ChatService.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 12/04/25.
//

import Foundation
import SocketIO

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var chats: [Chat] = []
    static let shared = ChatService()
    
    private let manager = SocketManager(socketURL: URL(string: "http://localhost:8000")!, config: [.log(true), .compress])
    private var socket: SocketIOClient {
        return manager.defaultSocket
    }
    
    init() {
        setupSocket()
    }
    
    private func setupSocket() {
        socket.connect()
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("🟢 Socket connected")
            // Reconnect user when socket connects
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                self?.setUserId(userId)
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("🔴 Socket disconnected")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self?.socket.connect()
            }
        }
        
        socket.on(clientEvent: .error) { [weak self] error, _ in
            print("❌ Socket error: \(error)")
            if let error = error as? Error {
                print("Socket error: \(error.localizedDescription)")
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self?.socket.connect()
            }
        }
        
        // Add ping/pong to maintain connection
        socket.on(clientEvent: .ping) { _, _ in
            print("Ping")
        }
        
        socket.on(clientEvent: .pong) { _, _ in
            print("Pong")
        }
        
        // Listen for incoming messages
        socket.on("receive-message") { [weak self] data, _ in
            guard let self = self,
                  let messageData = data.first as? [String: Any] else {
                print("❌ Invalid message data format")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: messageData)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
                
                let message = try decoder.decode(Message.self, from: jsonData)
                
                Task { @MainActor in
                    // Update messages array
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                        self.messages.sort { $0.createdAt < $1.createdAt }
                    }
                    
                    // Update chat's last message
                    if let chatIndex = self.chats.firstIndex(where: { $0.id == message.chatId }) {
                        var updatedChat = self.chats[chatIndex]
                        updatedChat.lastMessage = message.text
                        updatedChat.lastMessageAt = message.createdAt
                        
                        // Move updated chat to top of the list
                        self.chats.remove(at: chatIndex)
                        self.chats.insert(updatedChat, at: 0)
                    }
                    
                    // Notify observers
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NewMessageReceived"),
                        object: message
                    )
                }
            } catch {
                print("❌ Error processing received message: \(error)")
            }
        }
    }
    
    private func handleNewMessage(_ message: Message) {
        // Update messages array if not already present
        if !self.messages.contains(where: { $0.id == message.id }) {
            self.messages.append(message)
            self.messages.sort { $0.createdAt < $1.createdAt }
        }
        
        // Update chat's last message and unread count
        if let chatIndex = self.chats.firstIndex(where: { $0.id == message.chatId }) {
            var updatedChat = self.chats[chatIndex]
            updatedChat.lastMessage = message.text
            updatedChat.lastMessageAt = message.createdAt
            
            // Update unread count for the receiver
            if let receiverId = message.receiverId,
               let currentUserId = UserDefaults.standard.string(forKey: "userId"),
               receiverId == currentUserId {
                updatedChat.unreadCount[currentUserId] = (updatedChat.unreadCount[currentUserId] ?? 0) + 1
            }
            
            // Move updated chat to top of the list
            self.chats.remove(at: chatIndex)
            self.chats.insert(updatedChat, at: 0)
        }
    }
    
    func setUserId(_ id: String) {
        socket.emit("join", id)
    }
    
    func sendMessage(senderId: String, receiverId: String, text: String) {
        let payload: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId,
            "text": text
        ]
        
        socket.emit("send-message", payload)
        
        // Create and add temporary message locally
        let chatId = [senderId, receiverId].sorted().joined(separator: "_")
        let tempMessage = Message(
            id: UUID().uuidString,
            chatId: chatId,
            senderId: senderId,
            receiverId: receiverId,
            text: text,
            createdAt: Date()
        )
        
        Task { @MainActor in
            // Add message to messages array
            if !self.messages.contains(where: { $0.id == tempMessage.id }) {
                self.messages.append(tempMessage)
                self.messages.sort { $0.createdAt < $1.createdAt }
            }
            
            // Update chat's last message
            if let chatIndex = self.chats.firstIndex(where: { $0.id == chatId }) {
                var updatedChat = self.chats[chatIndex]
                updatedChat.lastMessage = text
                updatedChat.lastMessageAt = Date()
                self.chats[chatIndex] = updatedChat
            }
            
            // Notify observers
            NotificationCenter.default.post(
                name: NSNotification.Name("NewMessageReceived"),
                object: tempMessage
            )
        }
    }
    
    func fetchMessages(user1: String, user2: String) async {
        let url = Constants.URLs.fetchMessages(from: user1, to: user2)
        do {
            print("🔍 Fetching messages from: \(url)")
            var request = URLRequest(url: url)
            request.setValue("Bearer \(UserDefaults.standard.string(forKey: "token") ?? "")", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var processedMessages: [Message] = []
                
                for msgDict in jsonArray {
                    if let dateString = msgDict["createdAt"] as? String {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        if let date = formatter.date(from: dateString) {
                            let message = Message(
                                id: (msgDict["id"] as? String) ?? UUID().uuidString,
                                chatId: (msgDict["chatId"] as? String) ?? "",
                                senderId: (msgDict["senderId"] as? String) ?? "",
                                receiverId: (msgDict["receiverId"] as? String) ?? "",
                                text: (msgDict["text"] as? String) ?? "",
                                createdAt: date
                            )
                            processedMessages.append(message)
                        }
                    }
                }
                
                await MainActor.run {
                    self.messages = processedMessages
                    print("✅ Fetched \(processedMessages.count) messages")
                }
            }
        } catch {
            print("❌ Error fetching messages: \(error)")
            await MainActor.run {
                self.messages = []
            }
        }
    }
    
    func fetchChats() async {
        let url = Constants.URLs.fetchChats
        do {
            print("🔍 Fetching chats from: \(url)")
            var request = URLRequest(url: url)
            if let token = UserDefaults.standard.string(forKey: "token") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                print("🔑 Using token: \(token)")
            } else {
                print("⚠️ No authentication token found")
                return
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    print("❌ Authentication failed")
                    return
                }
            }
            
            // First try to decode the JSON to see what we're dealing with
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📋 Received Response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            
            var fetchedChats = try decoder.decode([Chat].self, from: data)
            
            // Load user details for all participants
            let allParticipantIds = Set(fetchedChats.flatMap { $0.participantIds })
            var users: [User] = []
            
            for userId in allParticipantIds {
                if let user = await fetchUser(userId: userId) {
                    users.append(user)
                }
            }
            
            // Update chats with full user objects
            for i in fetchedChats.indices {
                fetchedChats[i].updateParticipants(with: users)
            }
            
            await MainActor.run {
                self.chats = fetchedChats
                print("✅ Fetched \(fetchedChats.count) chats")
            }
        } catch {
            print("❌ Error fetching chats: \(error)")
        }
    }
    
    private func fetchUser(userId: String) async -> User? {
        let url = Constants.URLs.loadUserById(userId)
        do {
            var request = URLRequest(url: url)
            if let token = UserDefaults.standard.string(forKey: "token") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // First try to decode as UserResponse
            if let response = try? JSONDecoder().decode(UserResponse.self, from: data) {
                return response.effectiveUser
            }
            
            // If that fails, try to decode directly as User
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            print("❌ Error fetching user \(userId): \(error)")
            return nil
        }
    }
    
    func startChat(with userId: String) async -> Chat? {
        let url = Constants.URLs.startChat
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = UserDefaults.standard.string(forKey: "token") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                return nil
            }
            
            let payload = ["receiverId": userId]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            
            let chat = try decoder.decode(Chat.self, from: data)
            
            // Fetch user details in background
            Task { @MainActor in
                let users = await fetchUsersForChat(chat)
                var updatedChat = chat
                updatedChat.updateParticipants(with: users)
                
                if let existingIndex = self.chats.firstIndex(where: { $0.id == chat.id }) {
                    self.chats[existingIndex] = updatedChat
                } else {
                    self.chats.append(updatedChat)
                }
            }
            
            return chat
        } catch {
            print("❌ Error starting chat: \(error)")
            return nil
        }
    }
    
    private func fetchUsersForChat(_ chat: Chat) async -> [User] {
        var users: [User] = []
        for participantId in chat.participantIds {
            if let user = await fetchUser(userId: participantId) {
                users.append(user)
            }
        }
        return users
    }
    
    func markChatAsRead(chatId: String) async {
        let url = Constants.URLs.markChatAsRead(chatId: chatId)
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            if let token = UserDefaults.standard.string(forKey: "token") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (_, _) = try await URLSession.shared.data(for: request)
            
            // Update local chat's unread count
            if let chatIndex = self.chats.firstIndex(where: { $0.id == chatId }),
               let userId = UserDefaults.standard.string(forKey: "userId") {
                var updatedChat = self.chats[chatIndex]
                updatedChat.unreadCount[userId] = 0
                self.chats[chatIndex] = updatedChat
            }
            
            print("✅ Chat marked as read")
        } catch {
            print("❌ Error marking chat as read: \(error)")
        }
    }
}
