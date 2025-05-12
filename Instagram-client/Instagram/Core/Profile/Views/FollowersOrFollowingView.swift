//
//  FollowersOrFollowingView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 08/04/25.
//

import SwiftUI

struct FollowersOrFollowingView: View {
    @State private var selectedTab = 0
    let tabs = ["Followers", "Following"]
    @State private var searchText = ""
    let user: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ProfileViewModel()
    @State private var displayUser: User
    @State private var selectedUser: User?
    @State private var showChat = false
    @StateObject private var chatViewModel: ChatViewModel
    
    init(user: User) {
        self.user = user
        self._displayUser = State(initialValue: user)
        self._chatViewModel = StateObject(wrappedValue: ChatViewModel(currentUser: user))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with username and back button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(user.username)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                //tab selection
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        VStack(spacing: 4) {
                            Text(tabs[index])
                                .font(.system(size: 15))
                                .fontWeight(.regular)
                                .padding(.vertical, 8)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(selectedTab == index ? .primary : .clear)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTab = index
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                ScrollView {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    if selectedTab == 0 {
                        followersList
                    } else {
                        followingList
                    }
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let selectedUser = selectedUser {
                    ChatView(currentUser: user, chatUser: selectedUser, chatViewModel: chatViewModel)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .onAppear {
            Task {
                if let userId = user.id {
                    await vm.fetchUser(userId: userId)
                    if let updatedUser = vm.currentUser {
                        self.displayUser = updatedUser
                        print("Successfully loaded user data in followers/following view")
                    } else {
                        print("Failed to load user data")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var followersList: some View {
        Group {
            if displayUser.followers.isEmpty {
                Text("No followers")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                let filteredFollowers = displayUser.followers.filter {
                    searchText.isEmpty ||
                    ($0.username?.lowercased().contains(searchText.lowercased()) ?? false)
                }
                ForEach(filteredFollowers, id: \.id) { follow in
                    if let profileImage = follow.profileImage,
                       let username = follow.username {
                        profileView(profileImage: profileImage, userName: username, user: follow)
                    }
                }
            }
        }
    }
    
    private var followingList: some View {
        Group {
            if displayUser.following.isEmpty {
                Text("Not following anyone")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                let filteredFollowing = displayUser.following.filter {
                    searchText.isEmpty ||
                    ($0.username?.lowercased().contains(searchText.lowercased()) ?? false)
                }
                ForEach(filteredFollowing, id: \.id) { following in
                    if let profileImage = following.profileImage,
                       let username = following.username {
                        profileView(profileImage: profileImage, userName: username, user: following)
                    }
                }
            }
        }
    }
    
    private func profileView(profileImage: String, userName: String, user: FollowUser) -> some View {
        HStack(spacing: 18) {
            CircularProfileImageView(urlString: profileImage, size: .xSmall)
            VStack(alignment: .leading) {
                Text(userName)
                Text("bio")
                    .font(.footnote)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button {
                if let userId = user.id,
                   let username = user.username {
                    selectedUser = User(id: userId, username: username, profileImage: user.profileImage, followers: [], following: [])
                    showChat = true
                }
            } label: {
                Text("Message")
                    .font(.subheadline)
                    .padding(6)
                    .padding(.horizontal, 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    }
            }
        }
        .padding(.horizontal, 18)
    }
}

#Preview {
    FollowersOrFollowingView(user: .placeholder)
}
