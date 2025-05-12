//
//  ChatView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 12/04/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    let user: User
    @State private var hasInitialLoad = false
    
    init(currentUser: User, chatUser: User, chatViewModel: ChatViewModel) {
        self.user = chatUser
        _viewModel = StateObject(wrappedValue: chatViewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading messages...")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button("Retry") {
                            Task {
                                await retryLoading()
                            }
                        }
                    }
                    .padding()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                VStack {
                                    CircularProfileImageView(urlString: user.profileImage ?? "", size: .large)
                                    Text(user.username)
                                        .font(.title2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 20)
                                
                                // Use LazyVStack for messages to improve performance
                                LazyVStack(spacing: 8) {
                                    ForEach(viewModel.messages) { msg in
                                        messageBubble(msg)
                                            .id(msg.id)
                                    }
                                }
                                
                                // Invisible anchor view at the bottom
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .padding()
                        }
                        .onAppear {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: viewModel.messages) { _, _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    
                    messageField()
                        .padding(.horizontal)
                }
            }
            .hideNavBarOnSwipe(false)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                leading()
                trailing()
            }
            .onAppear {
                if let userId = viewModel.currentUser.id {
                    ChatService.shared.setUserId(userId)
                }
            }
            .task {
                await retryLoading()
            }
            .onDisappear {
                Task { @MainActor in
                    viewModel.cleanup()
                }
            }
        }
    }
    // MARK: - Message Bubble
    @ViewBuilder
    private func messageBubble(_ msg: Message) -> some View {
        HStack {
            if viewModel.isMessageFromCurrentUser(msg) {
                Spacer()
                Text(msg.text)
                    .padding(10)
                    .padding(.horizontal, 4)
                    .background(Color.purple.opacity(0.8))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                Text(msg.text)
                    .padding(10)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.7))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Spacer()
            }
        }
        .id(msg.id)
    }
    private func messageField() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.purple)
            TextField("Message...", text: $viewModel.newMessageText, axis: .vertical)
                .padding(.leading, 4)
            if viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Image(systemName: "mic")
                Image(systemName: "photo")
                Image(systemName: "plus.circle")
            } else {
                Button {
                    Task {
                        if let chat = viewModel.chats.first(where: { $0.participants.contains(where: { $0.id == user.id }) }) {
                            await viewModel.sendMessage(in: chat)
                        }
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.purple)
                        .animation(.spring, value: viewModel.newMessageText)
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(8)
        .background(.ultraThinMaterial)        
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(lineWidth: 0.3)
        }
        .padding(.bottom, 6)
    }
    @ToolbarContentBuilder
    private func leading() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    CircularProfileImageView(urlString: user.profileImage ?? "", size: .xSmall)
                    Text(user.username)
                }
            }
        }
    }
    @ToolbarContentBuilder
    private func trailing() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                // TODO: Implement video call
            } label: {
                Image(systemName: "video")
            }
            Button {
                // TODO: Implement voice call
            } label: {
                Image(systemName: "phone")
            }
        }
    }
    
    private func retryLoading() async {
        hasInitialLoad = false
        viewModel.errorMessage = nil
        do {
            if let chat = try await viewModel.startChat(with: user.id ?? "") {
                // Load messages first
                await viewModel.loadMessages(for: chat)
                // Then mark as read
                await viewModel.markChatAsRead(chat)
            }
            hasInitialLoad = true
        } catch {
            print("Error starting chat: \(error)")
            viewModel.errorMessage = "Failed to start chat. Please try again."
        }
    }
}

#Preview {
    ChatView(currentUser: .placeholder, chatUser: .placeholder, chatViewModel: ChatViewModel(currentUser: .placeholder))
}
