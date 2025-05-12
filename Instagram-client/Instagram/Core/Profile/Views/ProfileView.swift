//
//  ProfileView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    let user: User
    @StateObject private var vm = ProfileViewModel()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // Use the view model's follower and following counts
                ProfileHeaderView(
                    user: user,
                    followersCount: vm.followersCount,
                    followingCount: vm.followingCount,
                    postCount: vm.postCount
                )
                profileButtons()
                Spacer()
                ProfilePostsTabView(user: UserInfo(httpClient: .development), userId: user.id ?? "")
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                        .onTapGesture {
                            dismiss()
                        }
                    Text(user.username)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "ellipsis")
                        .imageScale(.large)
                }
            }
        }
        .task {
            // Load user data when the view appears
            if let userId = user.id {
                await vm.fetchUser(userId: userId)
            }
        }
    }

    private func profileButtons() -> some View {
        HStack {
            Button(vm.isFollowing ? "Unfollow" : "Follow") {
                Task {
                    await vm.toggleFollow(user: user)
                }
            }
            .padding(8)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 45)
            .background(vm.isFollowing ? Color.clear : Color.blue.opacity(0.9))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.border, lineWidth: 1)
            )
            
            Button("Share Profile") {}
                .padding(8)
                .padding(.horizontal, 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.border, lineWidth: 1)
                }

            Button {} label: {
                Image(systemName: "person.badge.plus.fill")
                    .padding(7)
                    .padding(.horizontal, 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.border, lineWidth: 1)
                    }
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

struct ProfileHeaderView: View {
    let user: User
    let followersCount: Int
    let followingCount: Int
    let postCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 30) {
                CircularProfileImageView(urlString: user.profileImage, size: .small)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                detailView(count: "\(postCount)", title: "Posts")
                NavigationLink {
                    FollowersOrFollowingView(user: user)
                } label: {
                    detailView(count: "\(followersCount)", title: "Followers")
                }
                NavigationLink {
                    FollowersOrFollowingView(user: user)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    detailView(count: "\(followingCount)", title: "Following")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            bio()
        }
    }

    private func bio() -> some View {
        VStack(alignment: .leading) {
            Text(user.fullName ?? "")
                .bold()
                .padding(.top, -12)
            Text(user.bio ?? "")
                .lineLimit(6)
                .frame(width: 180, alignment: .leading)
        }
        .font(.subheadline)
        .padding(.horizontal)
    }

    private func detailView(count: String, title: String) -> some View {
        VStack {
            Text(count)
            Text(title)
        }
        .font(.footnote)
    }
}

#Preview {
    ProfileView(user: .placeholder)
}
