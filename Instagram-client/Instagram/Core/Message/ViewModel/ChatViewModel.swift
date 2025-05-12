//
//  MessageViewModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 12/04/25.
//

import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var newMessageText: String = ""
    @Published var isTyping: Bool = false
    
    private let chatService = ChatService.shared
    private var typingTimer: Timer?
    private var messageObserver: NSObjectProtocol?
    let currentUser: User
    
    init(currentUser: User) {
        self.currentUser = currentUser
        setupMessageObserver()
    }
    
    private func setupMessageObserver() {
        // Remove any existing observer first
        if let observer = messageObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Observe messages from ChatService
        messageObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NewMessageReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let message = notification.object as? Message else { return }
            
            Task { @MainActor in
                // Only update if message belongs to current chat
                if let currentChatId = self.chats.first?.id,
                   message.chatId == currentChatId {
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                        // Sort messages by timestamp
                        self.messages.sort { $0.createdAt < $1.createdAt }
                    }
                }
                
                // Update unread count for all chats
                if let chatIndex = self.chats.firstIndex(where: { $0.id == message.chatId }),
                   let currentUserId = self.currentUser.id,
                   let receiverId = message.receiverId,
                   receiverId == currentUserId {
                    var updatedChat = self.chats[chatIndex]
                    updatedChat.unreadCount[currentUserId] = (updatedChat.unreadCount[currentUserId] ?? 0) + 1
                    self.chats[chatIndex] = updatedChat
                }
            }
        }
    }
    
    @MainActor
    func cleanup() {
        // Remove notification observer
        if let observer = messageObserver {
            NotificationCenter.default.removeObserver(observer)
            messageObserver = nil
        }
        
        // Cancel any pending timers
        typingTimer?.invalidate()
        typingTimer = nil
        
        // Clear messages and chats
        messages.removeAll()
        chats.removeAll()
        
        // Reset state
        isLoading = false
        errorMessage = nil
        newMessageText = ""
        isTyping = false
    }
    
    deinit {
        _ = { [weak self] in
            Task { await self?.cleanup() }
        }
    }
    
    // MARK: - Chat Functions
    
    func fetchChats() async throws {
        isLoading = true
        errorMessage = nil
        
        await chatService.fetchChats()
        chats = chatService.chats
        
        isLoading = false
    }
    
    func startChat(with userId: String) async throws -> Chat? {
        guard !isLoading else { return nil }
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        if let chat = await chatService.startChat(with: userId) {
            if !chats.contains(where: { $0.id == chat.id }) {
                chats.append(chat)
            }
            return chat
        } else {
            errorMessage = "Failed to start new chat"
            return nil
        }
    }
    
    func markChatAsRead(_ chat: Chat) async {
        guard let currentUserId = currentUser.id else { return }
        
        // Update local unread count first
        if let chatIndex = chats.firstIndex(where: { $0.id == chat.id }) {
            var updatedChat = chats[chatIndex]
            updatedChat.unreadCount[currentUserId] = 0
            chats[chatIndex] = updatedChat
        }
        
        // Then mark as read on server
        await chatService.markChatAsRead(chatId: chat.id)
    }
    
    // MARK: - Message Functions
    
    func sendMessage(in chat: Chat) async {
        guard let currentUserId = currentUser.id,
              let otherUser = getOtherParticipant(in: chat),
              let otherUserId = otherUser.id,
              !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let messageText = newMessageText
        newMessageText = "" // Clear text field immediately
        
        // Create temporary message
        let tempMessage = Message(
            id: UUID().uuidString,
            chatId: chat.id,
            senderId: currentUserId,
            receiverId: otherUserId,
            text: messageText,
            createdAt: Date()
        )
        
        // Add temporary message locally
        messages.append(tempMessage)
        
        // Send message through service
        chatService.sendMessage(
            senderId: currentUserId,
            receiverId: otherUserId,
            text: messageText
        )
    }
    
    func loadMessages(for chat: Chat) async {
        guard !isLoading else { return }
        isLoading = true
        
        guard let currentUserId = currentUser.id,
              let otherUser = getOtherParticipant(in: chat),
              let otherUserId = otherUser.id else {
            isLoading = false
            return
        }
        
        await chatService.fetchMessages(user1: currentUserId, user2: otherUserId)
        messages = chatService.messages
        
        isLoading = false
    }
    
    // MARK: - Typing Indicator
    
    func startTyping() {
        isTyping = true
        typingTimer?.invalidate()
        
        // Use Task to handle the timer in a way that's compatible with Swift 6
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            isTyping = false
        }
    }
    
    // MARK: - Helper Functions
    
    func filterChats(with searchText: String) -> [Chat] {
        if searchText.isEmpty {
            return chats
        } else {
            return chats.filter { chat in
                chat.participants.contains { user in
                    user.username.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    func getUnreadCount(for chat: Chat) -> Int {
        guard let currentUserId = currentUser.id else { return 0 }
        return chat.unreadCount[currentUserId] ?? 0
    }
    
    func getOtherParticipant(in chat: Chat) -> User? {
        guard let currentUserId = currentUser.id else { return nil }
        return chat.participants.first { $0.id != currentUserId }
    }
    
    func formatLastMessageTime(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    func getLastMessagePreview(for chat: Chat) -> String {
        if chat.lastMessage.isEmpty {
            return "No messages yet"
        } else {
            return chat.lastMessage
        }
    }
    
    func isMessageFromCurrentUser(_ message: Message) -> Bool {
        guard let currentUserId = currentUser.id else { return false }
        return message.senderId == currentUserId
    }
}
