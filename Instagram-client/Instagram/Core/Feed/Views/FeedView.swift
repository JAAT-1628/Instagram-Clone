//
//  FeedView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 26/02/25.
//

import SwiftUI

struct FeedView: View {
    @State private var hideNavBar = true
    @StateObject private var userInfo = UserInfo(httpClient: .development)
    @Binding var selectedTab: Int
    @State private var hasUnreadNotifications = false
    @StateObject private var profileVM = ProfileViewModel()
    @AppStorage("userId") private var userId: String?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                storyView()
                    .padding(.bottom)
                FeedCellView(selectedTab: $selectedTab)
            }
            .hideNavBarOnSwipe(hideNavBar)
            .toolbar {
                logo()
                navTrailingButtons()
            }
            .navigationDestination(for: User.self) { user in
                ProfileView(user: user)
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $hasUnreadNotifications) {
                if let user = profileVM.currentUser {
                    NotificationView(user: user)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .task {
            do {
                if let userId = UserDefaults.standard.string(forKey: "userId") {
                    try await userInfo.loadAllUser()
                    await profileVM.fetchUser(userId: userId)
                }
                if let userId = profileVM.currentUser?.id {
                    RealTimeNotificationManager.shared.connect(userId: userId) { _ in
                        DispatchQueue.main.async {
                            hasUnreadNotifications = true
                        }
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
        .onDisappear {
            RealTimeNotificationManager.shared.disconnect()
        }
    }
    
    private func storyView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                if let currentUser = profileVM.currentUser {
                    storyItem(for: currentUser, label: "You", showGradient: false)
                }
                
                ForEach(filteredUsers, id: \.id) { user in
                    storyItem(for: user, label: user.username, showGradient: true)
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ToolbarContentBuilder
    private func logo() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Label("Following", systemImage: "person.2")
                Label("Favourites", systemImage: "star")
            } label: {
                Image("logo")
                    .resizable()
                    .frame(width: 105, height: 40)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func navTrailingButtons() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                hasUnreadNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "heart")
                        .badge(hasUnreadNotifications ? "." : "")
                }
            }
            
            NavigationLink {
                if let user = profileVM.currentUser {
                    MessageView(currentUser: user)
                        .navigationBarBackButtonHidden(true)
                        .toolbar(.hidden, for: .tabBar)
                }
            } label: {
                Image("message")
                    .resizable()
                    .frame(width: 22, height: 22)
            }
        }
    }
    @ViewBuilder
    private func storyItem(for user: User, label: String, showGradient: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if showGradient {
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [.red, .orange, .purple, .red]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 64, height: 64)
                }
                
                CircularProfileImageView(urlString: user.profileImage, size: .small)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .frame(width: 60, height: 60)
            }
            
            Text(label)
                .font(.caption)
                .lineLimit(1)
        }
    }
    
    private var filteredUsers: [User] {
        guard let currentUser = profileVM.currentUser,
              let allUsers = userInfo.allUser else { return [] }
        
        let followingIds = currentUser.following.compactMap { $0.id }
        let followerIds = currentUser.followers.compactMap { $0.id }
        let connectionIds = Set(followingIds + followerIds)
        
        return allUsers.filter { user in
            user.id != currentUser.id && connectionIds.contains(user.id ?? "")
        }
    }
}

#Preview {
    FeedView(selectedTab: .constant(0))
}
