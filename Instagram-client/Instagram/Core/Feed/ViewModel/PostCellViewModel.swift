//
//  PostCellViewModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 09/04/25.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 16.0, *)
extension PostCellViewModel: @unchecked Sendable {}

class PostCellViewModel: ObservableObject {
    static var playingCellId: String?

    @Published var post: PostModel
    @Published var isLiked: Bool = false
    @Published var showComments: Bool = false
    @Published var showPostAction: Bool = false
    @Published var showFullDescription: Bool = false
    @Published var player: AVPlayer? = nil
    @Published var isVisible: Bool = false
    @Published var isVideoReady: Bool = false
    @Published var isMuted: Bool = true
    @Published var videoHeight: CGFloat = 300
    @Published var isTopMostVisibleVideo: Bool = false
    @Published var cellFrame: CGRect = .zero

    let postService: PostService

    init(post: PostModel, postService: PostService) {
        self.post = post
        self.postService = postService
        checkIfLiked()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanup()
    }
    

    func checkIfLiked() {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return }
        isLiked = post.likes.contains(currentUserId)
    }

    var isLikedByCurrentUser: Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return false }
        return post.likes.contains(currentUserId)
    }

    func likePost() {
        Task {
            if let updated = await postService.likePost(postId: post.id ?? "") {
                await MainActor.run {
                    self.update(with: updated)
                }
            }
        }
    }
    
    func update(with new: PostModel) {
        post.likes = new.likes
        post.comments = new.comments
        checkIfLiked()
    }


    func setupVideo(url: URL) {
        isVideoReady = false
        player = AVPlayer()
        player?.isMuted = isMuted

        let asset = AVURLAsset(url: url)

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let isPlayable = try await asset.load(.isPlayable)
                guard isPlayable else {
                    print("Video not playable")
                    return
                }

                let item = AVPlayerItem(asset: asset)
                await MainActor.run {
                    self.player?.replaceCurrentItem(with: item)
                    self.player?.actionAtItemEnd = .none
                }

                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                       object: item,
                                                       queue: .main) { _ in
                    self.player?.seek(to: .zero)
                    self.player?.play()
                }

                if #available(iOS 16.0, *) {
                    let videoTracks = try await asset.loadTracks(withMediaType: .video)
                    if let firstTrack = videoTracks.first {
                        let naturalSize = try await firstTrack.load(.naturalSize)
                        let transform = try await firstTrack.load(.preferredTransform)
                        let size = naturalSize.applying(transform)
                        let aspectRatio = abs(size.height / size.width)
                        let width = await UIScreen.main.bounds.width
                        let calculatedHeight = width * aspectRatio

                        await MainActor.run {
                            self.isVideoReady = true
                            self.videoHeight = calculatedHeight
                            self.updateVisibility()
                        }
                    }
                } else {
                    let tracks = asset.tracks(withMediaType: .video)
                    if let firstTrack = tracks.first {
                        let size = firstTrack.naturalSize.applying(firstTrack.preferredTransform)
                        let aspectRatio = abs(size.height / size.width)
                        let width = await UIScreen.main.bounds.width
                        let calculatedHeight = width * aspectRatio

                        await MainActor.run {
                            self.isVideoReady = true
                            self.videoHeight = calculatedHeight
                            self.updateVisibility()
                        }
                    }
                }
            } catch {
                print("Error loading video: \(error)")
                await MainActor.run {
                    self.isVideoReady = true
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            if !self.isVideoReady {
                self.isVideoReady = true
            }
        }
    }

    func updateVisibility() {
        let screenHeight = UIScreen.main.bounds.height
        let midY = cellFrame.midY
        let newIsVisible = midY > 100 && midY < screenHeight - 100

        if isVisible != newIsVisible {
            isVisible = newIsVisible
        }

        if isVisible {
            if PostCellViewModel.playingCellId == nil ||
               (PostCellViewModel.playingCellId != post.id && shouldBeTopMostVideo()) {
                PostCellViewModel.playingCellId = post.id
                NotificationCenter.default.post(name: NSNotification.Name("CheckForTopMostVideo"), object: nil)
            }

            let shouldBePlaying = post.id == PostCellViewModel.playingCellId
            if isTopMostVisibleVideo != shouldBePlaying {
                isTopMostVisibleVideo = shouldBePlaying
            }
        } else {
            if PostCellViewModel.playingCellId == post.id {
                PostCellViewModel.playingCellId = nil
                NotificationCenter.default.post(name: NSNotification.Name("CheckForTopMostVideo"), object: nil)
            }

            if isTopMostVisibleVideo {
                isTopMostVisibleVideo = false
            }
        }
    }

    func shouldBeTopMostVideo() -> Bool {
        if PostCellViewModel.playingCellId == nil {
            return true
        }

        if let storedY = UserDefaults.standard.object(forKey: "CurrentPlayingCellY") as? CGFloat {
            return cellFrame.minY < storedY
        }

        return true
    }

    func updateCurrentPlayingPosition() {
        if PostCellViewModel.playingCellId == post.id {
            UserDefaults.standard.set(cellFrame.minY, forKey: "CurrentPlayingCellY")
        }
    }

    func playVideoIfTopMost() {
        if isTopMostVisibleVideo {
            player?.play()
        }
    }

    func pauseVideo() {
        player?.pause()
    }

    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    func cleanup() {
        pauseVideo()
        player = nil

        if PostCellViewModel.playingCellId == post.id {
            PostCellViewModel.playingCellId = nil
            NotificationCenter.default.post(name: NSNotification.Name("CheckForTopMostVideo"), object: nil)
        }
    }
}
