//
//  ProfilePostsTabView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 26/02/25.
//

import SwiftUI
import Kingfisher

struct ProfilePostsTabView: View {
    @State private var selectedTab = 0
    let width = (UIScreen.main.bounds.width / 2.5)
    let icons = ["square.grid.3x3.fill", "person.crop.square"]
    @Namespace private var underlineNamespace
    private let gridItem: [GridItem] = [
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1)
    ]
    
    @StateObject private var vm = PostService(httpClient: .development)
    @ObservedObject var user: UserInfo
    var userId: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(0..<icons.count, id: \.self) { index in
                    Button {
                        withAnimation {
                            selectedTab = index
                        }
                    } label: {
                        VStack {
                            Image(systemName: icons[index])
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            if selectedTab == index {
                                Rectangle()
                                    .frame(width: 60, height: 1.8)
                                    .matchedGeometryEffect(id: "tabIndicator", in: underlineNamespace)
                            }
                        }
                    }
                    .frame(width: width)
                }
            }
            getContentTab(selectedTab)
        }
        
        .task {
            await vm.loadUserPosts(userId: userId)
            try? await user.loadUserInfo(userId: userId)
        }
    }
    
    @ViewBuilder
    private func getContentTab(_ value: Int) -> some View {
        switch value {
        case 0:
            postView
            
        case 1:
            let title = "Photos and videos of you"
            let title2 = "When people tag you in photos and videos, they'll appear here."
            noVideoView(image: "person.crop.square", title: title, title2: title2)
            
        default:
            EmptyView()
        }
    }
    
    private var postView: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 50)
            } else if vm.userPosts.isEmpty {
                noVideoView(
                    image: "camera",
                    title: "No Posts Yet",
                    title2: "When you share photos and videos, they'll appear on your profile."
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: gridItem, spacing: 1) {
                        ForEach(vm.userPosts) { post in
                            let mediaWidth = UIScreen.main.bounds.width / 3
                            if let user = user.user {
                                NavigationLink(destination: PostDetailView(post: post, user: user)) {
                                    if post.mediaType == .video, let videoURL = URL(string: post.videoUrl ?? "") {
                                        VideoThumbnailView(videoUrl: videoURL)
                                            .frame(width: mediaWidth, height: mediaWidth)
                                            .clipped()
                                            .overlay(
                                                Image(systemName: "play.circle.fill")
                                                    .resizable()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.white)
                                                    .padding(6),
                                                alignment: .bottomTrailing
                                            )
                                    } else if let imageURL = URL(string: post.imageUrl ?? "") {
                                        KFImage(imageURL)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: mediaWidth, height: mediaWidth)
                                            .clipped()
                                    } else {
                                        Color.gray
                                            .frame(width: mediaWidth, height: mediaWidth)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
    
    private func noVideoView(image: String, title: String, title2: String?) -> some View {
        VStack {
            Image(systemName: image)
                .resizable()
                .frame(width: 40, height: 40)
                .overlay {
                    Circle()
                        .stroke(Color.border, lineWidth: 2)
                        .frame(width: 70, height: 70)
                }
                .padding()
            VStack {
                Text(title)
                if let title2 {
                    Text(title2)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
            }
            .frame(width: 300, height: 70)
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProfilePostsTabView(user: UserInfo(httpClient: .development), userId: "dummyId")
}
