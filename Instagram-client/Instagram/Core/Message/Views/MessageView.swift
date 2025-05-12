//
//  MessageView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 28/02/25.
//

import SwiftUI

struct MessageView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: MessageViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
    init(currentUser: User) {
        _viewModel = StateObject(wrappedValue: MessageViewModel(currentUser: currentUser))
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(currentUser: currentUser))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    searchField()
                        .padding(.top, 8)
                    if viewModel.isLoading {
                        VStack(spacing: 20) {
                            ForEach(0..<9) { _ in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.8))
                                        .frame(width: 50, height: 50)
                                        .shimmering()
                                    VStack(alignment: .leading, spacing: 8) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.8))
                                            .frame(width: 120, height: 16)
                                            .shimmering()
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.8))
                                            .frame(width: 200, height: 12)
                                            .shimmering()
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                    } else {
                        List {
                            Section {
                                messagesList()
                            } header: {
                                Text("Messages")
                                    .textCase(nil)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            Section {
                                suggestedProfiles()
                            } header: {
                                Text("Suggestions")
                                    .textCase(nil)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .listStyle(.grouped)
                    }
                }
            }
            .hideNavBarOnSwipe(false)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                leadingButtons()
                trailingButtons()
            }
            .task {
                await viewModel.loadData()
                try? await chatViewModel.fetchChats()
            }
        }
    }
    
    private func messagesList() -> some View {
        Group {
            ForEach(chatViewModel.chats) { chat in
                if let otherUser = chatViewModel.getOtherParticipant(in: chat),
                   !chat.lastMessage.isEmpty {
                    NavigationLink {
                        ChatView(currentUser: viewModel.currentUser, chatUser: otherUser, chatViewModel: chatViewModel)
                            .navigationBarBackButtonHidden(true)
                            .toolbar(.hidden, for: .tabBar)
                    } label: {
                        HStack {
                            CircularProfileImageView(urlString: otherUser.profileImage ?? "", size: .small)
                            VStack(alignment: .leading) {
                                Text(otherUser.username)
                                    .font(.subheadline)
                                Text(chatViewModel.getLastMessagePreview(for: chat))
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(chatViewModel.formatLastMessageTime(chat.lastMessageAt))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                if chatViewModel.getUnreadCount(for: chat) > 0 {
                                    Text("\(chatViewModel.getUnreadCount(for: chat))")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            if chatViewModel.chats.allSatisfy({ $0.lastMessage.isEmpty }) {
                Text("No Chats, start a new one!")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    private func suggestedProfiles() -> some View {
        ScrollView {
            if viewModel.followingUsers.isEmpty {
                Text("Follow someone to start chatting")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVStack {
                    ForEach(viewModel.filteredFollowingUsers) { followUser in
                        NavigationLink {
                            ChatView(currentUser: viewModel.currentUser, chatUser: followUser, chatViewModel: chatViewModel)
                                .navigationBarBackButtonHidden(true)
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            suggestions(profileImage: followUser.profileImage ?? "", userName: followUser.username)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
    
    private func suggestions(profileImage: String, userName: String) -> some View {
        HStack {
            CircularProfileImageView(urlString: profileImage, size: .small)
            VStack(alignment: .leading) {
                Text(userName)
                    .font(.subheadline)
                Text("Tap to start chat")
                    .font(.footnote)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Image(systemName: "camera")
        }
        .foregroundColor(.primary)
    }
    
    @ToolbarContentBuilder
    private func leadingButtons() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
            }
            Text(viewModel.currentUser.username)
        }
    }
    
    @ToolbarContentBuilder
    private func trailingButtons() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // TODO: Implement new chat button
            } label: {
                Image(systemName: "square.and.pencil")
                    .bold()
            }
        }
    }
    
    private func searchField() -> some View {
        HStack {
            Image("aichat")
                .resizable()
                .frame(width: 24, height: 24)
            TextField("Ask Meta AI or search", text: $viewModel.searchText)
        }
        .font(.subheadline)
        .padding(8)
        .padding(.horizontal, 4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
        .padding(.horizontal)
    }
}

#Preview {
    MessageView(currentUser: .placeholder)
}
