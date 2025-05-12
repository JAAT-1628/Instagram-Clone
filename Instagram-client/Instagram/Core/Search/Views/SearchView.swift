//
//  SearchView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 26/02/25.
//

import SwiftUI
import Kingfisher

struct SearchView: View {
    @State private var isSearchActive = false
    @Namespace var animation
    @StateObject private var vm = PostService(httpClient: .development)
    @State private var user = UserInfo(httpClient: .development)
    @State private var selectedTab: Int = 0
    
    // Layout configuration
    private let gridSpacing: CGFloat = 1
    
    var body: some View {
        NavigationView {
            if isSearchActive {
                withAnimation(.spring(duration: 1)) {
                    SearchBarView(animation: animation, dismissSearch: $isSearchActive)
                        .transition(.opacity.animation(.smooth))
                }
            } else {
                VStack(spacing: 0) {
                    searchBarHeader()
                    
                    ScrollView(showsIndicators: false) {
                        simplifiedInstagramGrid()
                    }
                }
                .task {
                    await vm.loadAllPosts()
                }
            }
        }
    }
    
    // Search bar at the top
    @ViewBuilder
    private func searchBarHeader() -> some View {
        HStack {
            ZStack {
                if isSearchActive {
                    searchBar()
                } else {
                    searchBar()
                        .matchedGeometryEffect(id: "searchbar", in: animation)
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut) {
                    isSearchActive = true
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Simplified Instagram grid pattern
    @ViewBuilder
    private func simplifiedInstagramGrid() -> some View {
        let width = UIScreen.main.bounds.width
        let smallItemWidth = (width - gridSpacing * 2) / 3
        let largeItemWidth = width  // Full width for large items
        
        let posts = vm.posts
        
        VStack(spacing: gridSpacing) {
            // First row: 3 items (2 small with video, 1 large)
            if posts.count > 0 {
                HStack(spacing: gridSpacing) {
                    // First column: 2 small items vertically stacked
                    VStack(spacing: gridSpacing) {
                        // Top item (small) - video if available
                        if posts.count > 0 {
                            let post = posts[0]
                            postItem(post: post, width: smallItemWidth, height: smallItemWidth)
                        }
                        
                        // Bottom item (small)
                        if posts.count > 3 {
                            let post = posts[3]
                            postItem(post: post, width: smallItemWidth, height: smallItemWidth)
                        } else {
                            Color.gray.frame(width: smallItemWidth, height: smallItemWidth)
                        }
                    }
                    
                    // Second column: 1 large item spanning 2 rows
                    if posts.count > 1 {
                        let post = posts[1]
                        postItem(post: post, width: smallItemWidth * 2 + gridSpacing, height: smallItemWidth * 2 + gridSpacing)
                    } else {
                        Color.gray.frame(width: smallItemWidth * 2 + gridSpacing, height: smallItemWidth * 2 + gridSpacing)
                    }
                }
            }
            
            // Second row: 1 large item
            if posts.count > 4 {
                let post = posts[4]
                postItem(post: post, width: largeItemWidth, height: smallItemWidth * 2 + gridSpacing)
            }
            
            // For the remainder of posts, can follow a standard grid pattern...
            if posts.count > 5 {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: gridSpacing),
                    GridItem(.flexible(), spacing: gridSpacing),
                    GridItem(.flexible(), spacing: gridSpacing)
                ], spacing: gridSpacing) {
                    ForEach(5..<posts.count, id: \.self) { index in
                        let post = posts[index]
                        postItem(post: post, width: smallItemWidth, height: smallItemWidth)
                    }
                }
            }
        }
    }
    
    // Individual post item with navigation
    @ViewBuilder
    private func postItem(post: PostModel, width: CGFloat, height: CGFloat) -> some View {
        let bindingPost = Binding(get: { post }, set: { _ in })
        Group {
            if post.mediaType == .video, let videoURL = URL(string: post.videoUrl ?? "") {
                // Video item - navigate to ReelView
                NavigationLink(destination: ReelView().edgesIgnoringSafeArea(.top)) {
                    ZStack {
                        // Use black background as fallback until thumbnail loads 
                        Color.black
                        
                        // Video thumbnail
                        VideoThumbnailView(videoUrl: videoURL)
                            .frame(width: width, height: height)
                            .clipped()
                        
                        // Play button overlay
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                            .padding(6)
                            .position(x: width - 20, y: height - 20)
                    }
                    .frame(width: width, height: height)
                }
            } else if let imageURL = URL(string: post.imageUrl ?? "") {
                NavigationLink(destination: PostCell(post: bindingPost, postService: vm, selectedTab: $selectedTab)) {
                    KFImage(imageURL)
                        .placeholder { Color.gray }
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                }
            } else {
                // Placeholder when no media URL is available
                Color.gray
                    .frame(width: width, height: height)
            }
        }
        .contentShape(Rectangle())
    }
    
    // Search bar component
    @ViewBuilder
    private func searchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .imageScale(.medium)
                .foregroundStyle(.gray)
            TextField("search", text: .constant(""))
                .disabled(true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.7), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    SearchView()
}
