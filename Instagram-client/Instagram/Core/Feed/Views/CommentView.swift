//
//  CommentView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 07/04/25.
//

import SwiftUI

struct CommentView: View {
    @State private var newComment = ""
    @ObservedObject var viewModel: PostCellViewModel
    
    var body: some View {
        VStack {
            Text("Comments")
                .padding(.top)
            
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.post.comments ?? []) { comment in
                        HStack(alignment: .top, spacing: 12) {
                            CircularProfileImageView(urlString: comment.user?.profileImage, size: .xSmall)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(comment.user?.username ?? "Loading...")
                                    .font(.subheadline)

                                Text(comment.text)
                                    .font(.footnote)

                                Text(comment.date.TimeAgoSinceNow())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                        .id(comment.id)
                    }
                }
                .listStyle(.grouped)
                .onChange(of: viewModel.post.comments?.count ?? 0) {
                    if let lastId = viewModel.post.comments?.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    Task {
                        if let updated = await viewModel.postService.addComment(to: viewModel.post.id ?? "", commentText: newComment) {
                            await MainActor.run {
                                viewModel.update(with: updated)
                                newComment = ""
                            }
                        }
                    }
                }
                .disabled(newComment.isEmptyOrWhitespace)
            }
            .padding()
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
//    CommentView(viewModel: )
}
