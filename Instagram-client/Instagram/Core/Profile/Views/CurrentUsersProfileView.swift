//
//  CurrentUsersProfileView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 26/02/25.
//

import SwiftUI
import PhotosUI

struct CurrentUsersProfileView: View {
    @StateObject private var userInfo = UserInfo(httpClient: HTTPClient())
    @State private var showProfileEditSheet: Bool = false
    @AppStorage("userId") private var userId: String?

    @StateObject private var vm = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if let user = userInfo.user {
                        // Use the view model's follower and following counts
                        ProfileHeaderView(
                            user: user,
                            followersCount: vm.followersCount,
                            followingCount: vm.followingCount,
                            postCount: vm.postCount
                        )
                        
                    } else {
                        ProgressView()
                    }
                    profileButtons()
                    
                    Spacer()
                    ProfilePostsTabView(user: userInfo, userId: userInfo.user?.id ?? "")
                        .ignoresSafeArea()
                }
                .toolbar {
                    leadingUserName()
                    trailingButtons()
                }
            }
        }.task {
            // Load user data when the view appears
            if let userId = userInfo.user?.id {
                await vm.fetchUser(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showProfileEditSheet, onDismiss: {
            // Refresh profile data when returning from edit screen
            Task {
                try? await userInfo.loadUserInfo(userId: userInfo.user?.id ?? "")
            }
        }) {
            EditProfileView()
        }
    }
    
    @ToolbarContentBuilder
    private func leadingUserName() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text(userInfo.username)
        }
    }
    
    @ToolbarContentBuilder
    private func trailingButtons() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Image("threads")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.horizontal, 5)
            Image("plus")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.horizontal, 5)
            NavigationLink {
                OptionsView()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 20, height: 14)
            }
        }
    }
    
    private func profileButtons() -> some View {
        HStack {
            Button {
                showProfileEditSheet = true
            } label: {
                Text("Edit Profile")
                    .padding(8)
                    .padding(.horizontal, 30)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.border, lineWidth: 1)
                    }
            }
            Button {
                
            } label: {
                Text("Share Profile")
                    .padding(8)
                    .padding(.horizontal, 30)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.border, lineWidth: 1)
                    }
            }
            
            Button {
                
            } label: {
                Image(systemName: "person.badge.plus.fill")
                    .padding(7)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.border, lineWidth: 1)
                    }
            }

        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CurrentUsersProfileView()
}
