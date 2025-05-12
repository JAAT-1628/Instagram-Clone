//
//  FeedCellView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 26/02/25.
//

import SwiftUI
import Kingfisher

struct FeedCellView: View {
    @StateObject private var postService = PostService(httpClient: .development)
    @Binding var selectedTab: Int
    @State private var hasInitialLoad = false
    
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if postService.isLoading {
                    VStack(spacing: 20) {
                        ForEach(0..<3) { _ in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.8))
                                        .frame(width: 40, height: 40)
                                        .shimmering()
                                    VStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.8))
                                            .frame(width: 100, height: 16)
                                            .shimmering()
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.8))
                                            .frame(width: 60, height: 12)
                                            .shimmering()
                                    }
                                }
                                Rectangle()
                                    .fill(Color.gray.opacity(0.8))
                                    .frame(height: 300)
                                    .shimmering()
                                HStack(spacing: 20) {
                                    ForEach(0..<4) { _ in
                                        Circle()
                                            .fill(Color.gray.opacity(0.8))
                                            .frame(width: 24, height: 24)
                                            .shimmering()
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                } else if let error = postService.errorMessage {
                    Text("Error loading posts: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if postService.posts.isEmpty {
                    Text("No posts to display")
                        .padding()
                } else {
                    ForEach($postService.posts) { post in
                        PostCell(post: post, postService: postService, selectedTab: $selectedTab) {
                            postService.posts.removeAll(where: { $0.id == post.id })
                        }
                        .padding(.bottom, 10)
                    }
                }
            }
        }
        .refreshable {
            await postService.loadAllPosts()
        }
        .task {
//            if !hasInitialLoad {
                await postService.loadAllPosts()
//                hasInitialLoad = true
//            }
        }
    }
}


#Preview {
    FeedCellView(selectedTab: .constant(0))
}
