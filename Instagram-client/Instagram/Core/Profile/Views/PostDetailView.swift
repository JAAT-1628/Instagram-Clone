//
//  PostDetailView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 07/04/25.
//

import SwiftUI

struct PostDetailView: View {
    @State private var selectedTab: Int = 4
       let post: PostModel
       let user: User

       @StateObject private var vm = PostService(httpClient: .development)

       var body: some View {
           NavigationStack {
               ScrollView {
                   LazyVStack(spacing: 12) {
                       ForEach($vm.userPosts) { post in
                           PostCell(post: post, postService: vm, selectedTab: $selectedTab)
                       }
                   }
               }
               .navigationTitle("posts")
               .navigationBarTitleDisplayMode(.inline)
           }
           .task {
               await vm.loadUserPosts(userId: user.id ?? "")

               // Avoid modifying published property during observation
               let updatedPosts = vm.userPosts.map { post in
                   var updated = post
                   updated.user = user
                   return updated
               }

               vm.userPosts = updatedPosts
           }
       }
   }

#Preview {
//    PostDetailView(user: .placeholder)
}
