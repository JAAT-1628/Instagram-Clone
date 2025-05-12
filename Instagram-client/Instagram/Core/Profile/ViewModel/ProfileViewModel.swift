//
//  ProfileViewModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 08/04/25.
//

import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isFollowing: Bool = false
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var postCount: Int = 0
    
    private let userInfo = UserInfo(httpClient: .development)
    private let postService = PostService(httpClient: .development)
    
    func fetchUser(userId: String) async {
        do {
            // Get user with populated follow info
            let resource = Resource(
                url: Constants.URLs.getUserWithFollowInfo(userId),
                modelType: UserResponse.self
            )
            
            let response = try await userInfo.httpClient.load(resource)
            
            if let user = response.user {
                DispatchQueue.main.async {
                    self.currentUser = user
                    
                    // Update the counts from the arrays directly
                    self.followersCount = user.followers.count
                    self.followingCount = user.following.count
                    
                    // Check if current user follows this profile
                    if let currentUserId = UserDefaults.standard.string(forKey: "userId") {
                        self.isFollowing = user.followers.contains(where: { $0.id == currentUserId })
                    }
                }
                // Load posts to get post count
                await loadUserPostCount(userId: userId)
                
            }
        } catch {
            print("Failed to fetch user: \(error.localizedDescription)")
        }
    }
    
    private func loadUserPostCount(userId: String) async {
            await postService.loadUserPosts(userId: userId)
            DispatchQueue.main.async {
                self.postCount = self.postService.userPosts.count
            }
        }
        
    func toggleFollow(user: User) async {
        guard let userId = user.id else { return }
        
        do {
            let response = try await userInfo.followUser(userIdToFollow: userId)
            if response.success {
                // Optimistically update local state
                DispatchQueue.main.async {
                    self.isFollowing = !self.isFollowing
                    self.followersCount += self.isFollowing ? 1 : -1
                }
                
                // Refresh data to get accurate counts
                await fetchUser(userId: userId)
            }
        } catch {
            print("Follow/unfollow failed:", error.localizedDescription)
        }
    }
}
