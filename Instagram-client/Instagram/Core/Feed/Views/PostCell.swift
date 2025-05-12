//
//  PostCell.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 08/04/25.
//

import SwiftUI
import Kingfisher
import AVKit

struct PostCell: View {
    @ObservedObject private var viewModel: PostCellViewModel
    @Binding var selectedTab: Int
    @StateObject private var userService = UserInfo(httpClient: .development)
    private let postService: PostService
    let onDelete: (() -> Void)?
    
    init(post: Binding<PostModel>, postService: PostService, selectedTab: Binding<Int>, onDelete: (() -> Void)? = nil) {
        self.postService = postService
        self._viewModel = ObservedObject(wrappedValue: PostCellViewModel(post: post.wrappedValue, postService: postService))
        self._selectedTab = selectedTab
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            postHeader()
            postMediaContent()
            postButtons()
            postDescription()
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black)
        .onAppear {
            viewModel.checkIfLiked()
        }
        .sheet(isPresented: $viewModel.showComments) {
            CommentView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showPostAction) {
            PostActionView(post: viewModel.post) {
                Task {
                    await postService.loadAllPosts()
                }
            }
                .presentationDetents([.medium, .large])
        }
    }
    private func postHeader() -> some View {
        HStack {
            if viewModel.post.user.id ?? "" == userService.user?.id {
                Button {
                    selectedTab = 4
                } label: {
                    CircularProfileImageView(urlString: viewModel.post.user.profileImage, size: .xSmall)
                    Text(viewModel.post.user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            } else {
                NavigationLink(value: viewModel.post.user) {
                    HStack {
                        CircularProfileImageView(urlString: viewModel.post.user.profileImage, size: .xSmall)
                        Text(viewModel.post.user.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            Spacer()
            Button {
                viewModel.showPostAction = true
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .padding(.horizontal, 12)
    }
    
    
    private func postMediaContent() -> some View {
        Group {
            if viewModel.post.mediaType == .video,
               let videoUrlString = viewModel.post.videoUrl,
               let videoURL = URL(string: videoUrlString) {
                AutoVideoPlayer(url: videoURL)
                    .frame(maxWidth: .infinity)
                // Remove the forced aspect ratio here
                    .clipped()
            } else if let imageUrl = URL(string: viewModel.post.imageUrl ?? "") {
                KFImage(imageUrl)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            }
        }
    }
    private func postButtons() -> some View {
        HStack(spacing: 16) {
            Button {
                viewModel.likePost()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(viewModel.isLikedByCurrentUser ? .red : .primary)
                    Text("\(viewModel.post.likeCount)")
                }
            }
            Button {
                viewModel.showComments = true
            } label: {
                HStack(spacing: 4) {
                    Image("comment")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("\(viewModel.post.comments?.count ?? 0)")
                }
            }
            Button {
                // Share action
            } label: {
                Image("share")
                    .resizable()
                    .frame(width: 25, height: 25)
            }
            Spacer()
            Button {
                // Save action
            } label: {
                Image(systemName: "bookmark")
                    .resizable()
                    .frame(width: 15, height: 20)
            }
        }
        .font(.system(size: 14))
        .foregroundColor(.primary)
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
    }
    
    private func postDescription() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let caption = viewModel.post.caption, !caption.isEmpty {
                Text(caption)
                    .lineLimit(viewModel.showFullDescription ? 50 : 2)
                    .font(.footnote)
                    .onTapGesture {
                        viewModel.showFullDescription.toggle()
                    }
            }
            
            Text(viewModel.post.date.TimeAgoSinceNow())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#Preview {
//    FeedView(selectedTab: .constant(0))
}
