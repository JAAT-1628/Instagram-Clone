//
//  ReelViewModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 10/04/25.
//

import Foundation
import SwiftUI
import AVKit

@MainActor
class ReelViewModel: ObservableObject {
    private let postService: PostService
    let userService: UserInfo
    
    // Published properties
    @Published var reels: [PostModel] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLiked: [String: Bool] = [:]  // Dictionary to track liked status by reel ID
    @Published var activeVideoCellId: String? = nil
    @Published var playerViewModels: [String: PostCellViewModel] = [:]
    
    // Computed property for current reel
    var currentReel: PostModel? {
        guard !reels.isEmpty, currentIndex < reels.count else { return nil }
        return reels[currentIndex]
    }
    
    init(postService: PostService, userService: UserInfo) {
        self.postService = postService
        self.userService = userService
        
        // Listen for notifications about which video should be playing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkForTopMostVideo),
            name: NSNotification.Name("CheckForTopMostVideo"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func checkForTopMostVideo() {
        DispatchQueue.main.async {
            self.activeVideoCellId = PostCellViewModel.playingCellId
            self.objectWillChange.send()
        }
    }
    
    // Load all reels
    func loadReels() async {
        isLoading = true
        errorMessage = nil
        
             await postService.fetchAllReels()
            self.reels = postService.reels
            
            // Initialize like status for each reel
            for reel in reels {
                checkIfLiked(reel: reel)
                setupViewModelForReel(reel)
            }
        
        isLoading = false
    }
    
    private func setupViewModelForReel(_ reel: PostModel) {
        guard let reelId = reel.id else { return }
        
        // Create ViewModel if it doesn't exist
        if playerViewModels[reelId] == nil {
            let viewModel = PostCellViewModel(post: reel, postService: postService)
            playerViewModels[reelId] = viewModel
            
            // Setup video if URL exists
            if let videoUrlString = reel.videoUrl, let videoURL = URL(string: videoUrlString) {
                viewModel.setupVideo(url: videoURL)
            }
        }
    }
    
    // Check if the current user has liked a specific reel
    func checkIfLiked(reel: PostModel) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        let liked = reel.likes.contains(userId)
        isLiked[reel.id ?? ""] = liked
    }
    
    // Like or unlike a reel
    func toggleLike(for reelId: String) async {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let index = reels.firstIndex(where: { $0.id == reelId }) else { return }

        // Optimistically update UI
        let wasLiked = isLiked[reelId] ?? false
        isLiked[reelId] = !wasLiked

        var updatedReel = reels[index]
        if wasLiked {
            updatedReel.likes.removeAll(where: { $0 == userId })
        } else {
            updatedReel.likes.append(userId)
        }
        reels[index] = updatedReel

        // Update view model if exists
        playerViewModels[reelId]?.update(with: updatedReel)

        // Call API
        if let serverPost = await postService.likePost(postId: reelId) {
            reels[index] = serverPost
            checkIfLiked(reel: serverPost)
            playerViewModels[reelId]?.update(with: serverPost)
        } else {
            // Revert if API call fails
            isLiked[reelId] = wasLiked
            reels[index] = updatedReel // restore previous state
            checkIfLiked(reel: updatedReel)
        }
    }

    // Handle reel appearance/disappearance
    func reelAppeared(reelId: String, frame: CGRect) {
        if let viewModel = playerViewModels[reelId] {
            viewModel.cellFrame = frame
            viewModel.updateVisibility()
            viewModel.updateCurrentPlayingPosition()
        }
    }
    
    // Pause all videos when leaving the screen
    func pauseAllVideos() {
        for (_, viewModel) in playerViewModels {
            viewModel.pauseVideo()
        }
    }
    
    // Pause all videos except the one with the given ID
    func pauseAllExcept(_ exceptReelId: String) {
        for (reelId, viewModel) in playerViewModels {
            if reelId != exceptReelId {
                viewModel.pauseVideo()
            }
        }
    }
    
    // Cleanup resources
    func cleanup() {
        for (_, viewModel) in playerViewModels {
            viewModel.cleanup()
        }
        playerViewModels.removeAll()
    }

    func forcePlayVideo(reelId: String) {
        if let viewModel = playerViewModels[reelId] {
            viewModel.player?.volume = 1.0  // Ensure audio is enabled
            viewModel.player?.play()
            viewModel.updateVisibility()
            self.activeVideoCellId = reelId
            objectWillChange.send()
        }
    }
}

// Extension for PostCellViewModel to ensure proper video setup
extension PostCellViewModel {
    func setupReelVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Ensure audio is enabled
        player?.volume = 1.0
        
        // Add this to ensure video is prepared to play
        player?.automaticallyWaitsToMinimizeStalling = true
        
        // Preload the video
        player?.preroll(atRate: 1.0) { _ in
            DispatchQueue.main.async {
                self.isVideoReady = true
                self.objectWillChange.send()
            }
        }
    }
    
    func toggleToMute() {
        guard let player = player else { return }
        player.volume = player.volume > 0 ? 0 : 1
        objectWillChange.send()
    }
}
