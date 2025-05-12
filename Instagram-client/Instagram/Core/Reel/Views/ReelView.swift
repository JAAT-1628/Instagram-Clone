//
//  ReelView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 28/02/25.
//

import SwiftUI
import AVKit

struct ReelView: View {
    @StateObject private var viewModel: ReelViewModel
    @State private var commentText: String = ""
    @State private var showCommentSheet: Bool = false
    @State private var currentReelId: String? = nil
    @StateObject private var profileViewModel = ProfileViewModel()
    @AppStorage("userId") private var userId: String?
    @Environment(\.dismiss) private var dismiss
    
    init() {
        // Use async initialization in Task within body
        _viewModel = StateObject(wrappedValue: ReelViewModel(
            postService: PostService(httpClient: .development),
            userService: UserInfo(httpClient: .development)
        ))
    }
    
    var body: some View {
        ZStack {
            // Black background for video content
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else if viewModel.reels.isEmpty {
                Text("No reels found")
                    .foregroundColor(.white)
            } else {
                reelContent
            }
        }
        .task {
            await viewModel.loadReels()
        }
        .sheet(isPresented: $showCommentSheet) {
            if let reelId = currentReelId,
               let vm = viewModel.playerViewModels[reelId] {
                CommentView(viewModel: vm)
                    .presentationDetents([.medium, .large])
            }
        }
        .onDisappear {
            viewModel.pauseAllVideos()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .statusBar(hidden: true) // Hide status bar for full-screen experience
        .preferredColorScheme(.dark) // Force dark mode for proper appearance
    }
    
    // Main reel content view using paging scroll view
    private var reelContent: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.reels) { reel in
                        reelCell(for: reel, in: geometry)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
            .scrollTargetLayout()
            .scrollTargetBehavior(.paging)
            .onAppear {
                // Force play first video when view appears
                if let firstReel = viewModel.reels.first, let reelId = firstReel.id {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.reelAppeared(reelId: reelId,
                                            frame: CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height))
                        viewModel.forcePlayVideo(reelId: reelId)
                    }
                }
            }
        }
    }
    
    // Individual reel cell
    private func reelCell(for reel: PostModel, in geometry: GeometryProxy) -> some View {
        let reelId = reel.id ?? ""
        
        return GeometryReader { cellGeometry in
            ZStack(alignment: .center) {
                // Video player
                if let cellviewModel = viewModel.playerViewModels[reelId],
                   cellviewModel.isVideoReady,
                   let player = cellviewModel.player {
                    
                    CustomVideoPlayer(player: player)
                        .frame(width: cellGeometry.size.width, height: cellGeometry.size.height)
                        .overlay(
                            // Transparent overlay for gestures
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    Task {
                                        await viewModel.toggleLike(for: reelId)
                                    }
                                }
                                .onTapGesture(count: 1) {
                                    if let cellviewModel = viewModel.playerViewModels[reelId] {
                                        cellviewModel.toggleMute()
                                    }
                                }
                        )
                } else {
                    // Loading placeholder
                    Color.black
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Text("Loading reel...")
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                            }
                        )
                }
                
                // Top bar overlay
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Text("Reels")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: {
                            // Camera action
                        }) {
                            Image(systemName: "camera")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)
                    
                    Spacer()
                }
                
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                // Right side buttons (like, comment, share, etc.)
                VStack(alignment: .trailing, spacing: 20) {
                    Spacer()
                    
                    // Like button
                    VStack(alignment: .center, spacing: 2) {
                        Button {
                            Task {
                                await viewModel.toggleLike(for: reelId)
                            }
                        } label: {
                            Image(systemName: (viewModel.isLiked[reelId] ?? false) ? "heart.fill" : "heart")
                                .font(.system(size: 26))
                                .foregroundColor((viewModel.isLiked[reelId] ?? false) ? .red : .white)
                        }
                        
                        Text("\(reel.likeCount)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    // Comment button
                    VStack(alignment: .center, spacing: 2) {
                        Button {
                            currentReelId = reelId
                            showCommentSheet = true
                        } label: {
                            Image(.comment)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Text("\(reel.comments?.count ?? 0)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    // Share button
                    VStack(alignment: .center, spacing: 2) {
                        Button {
                           
                        } label: {
                            Image(.share)
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // More options button
                    Button {
                        // More options action
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    // Audio button with rotation
                    Button {
                        // Audio action
                    } label: {
                        Image(systemName: "music.note")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                
                // Bottom user info bar
                VStack {
                    Spacer()
                    HStack(alignment: .top) {
                        // User profile image
                        if let profileImageUrl = reel.user.profileImage {
                            AsyncImage(url: URL(string: profileImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 36, height: 36)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 28) {
                                Text(reel.user.username)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                if userId != reel.user.id {
                                    Button {
                                        Task {
                                            if let reelUserId = reel.user.id {
                                                await profileViewModel.fetchUser(userId: reelUserId)
                                                if let fetchedUser = profileViewModel.currentUser {
                                                    await profileViewModel.toggleFollow(user: fetchedUser)
                                                }
                                            }
                                        }
                                    } label: {
                                        Text(profileViewModel.isFollowing ? "Unfollow" : "Follow")
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            
                            // Caption directly under username
                            if let caption = reel.caption {
                                Text(caption)
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "music.note")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                Text("Original Audio")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.black.opacity(0),
                                    Color.black.opacity(0.5)
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .onAppear {
                currentReelId = reelId
                viewModel.reelAppeared(reelId: reelId, frame: cellGeometry.frame(in: .global))
            }
            .onChange(of: cellGeometry.frame(in: .global)) { oldValue, newValue in
                viewModel.reelAppeared(reelId: reelId, frame: newValue)
                
                // Check if this cell is now fully visible and play the video
                if isVisible(frame: newValue, in: geometry) {
                    viewModel.forcePlayVideo(reelId: reelId)
                    // Pause all other videos
                    viewModel.pauseAllExcept(reelId)
                } else {
                    // Explicitly pause this video if not visible
                    if let viewModel = viewModel.playerViewModels[reelId] {
                        viewModel.pauseVideo()
                    }
                }
            }
        }
    }
    
    // Helper to check if a frame is fully visible
    private func isVisible(frame: CGRect, in geometry: GeometryProxy) -> Bool {
        let screenMidY = geometry.frame(in: .global).midY
        let cellMidY = frame.midY
        
        // Consider visible only if very close to center
        return abs(screenMidY - cellMidY) < 30
    }

}
#Preview {
    ReelView()
}
