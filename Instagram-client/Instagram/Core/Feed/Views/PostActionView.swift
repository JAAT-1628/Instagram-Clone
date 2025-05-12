//
//  PostActionView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 10/04/25.
//

import SwiftUI

struct PostActionView: View {
    @StateObject private var postService = PostService(httpClient: .development)
    @AppStorage("userId") private var userId: String?
    let post: PostModel
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        List {
            // show if its current user post
            if userId == post.user.id {
                Section {
                    buttonStyle(image: "qrcode", text: "QR code")
                    buttonStyle(image: "person.circle", text: "Account info")
                    buttonStyle(image: "eye.slash", text: "Manage content preferences")
                    Button {
                        Task {
                            guard let postId = post.id, !postId.isEmpty else {
                                print("Post ID is nil or empty. Cannot delete.")
                                return
                            }
                            let success = await postService.deletePost(postId: postId)
                            if success { onDelete?() }
                        }
                    } label: {
                        buttonStyle(image: "delete.right", text: "delete")
                            .foregroundStyle(.red)
                    }
                }
            } else {
                Section {
                    buttonStyle(image: "qrcode", text: "QR code")
                    buttonStyle(image: "person.circle", text: "About this account")
                    buttonStyle(image: "translate", text: "Translations")
                    buttonStyle(image: "exclamationmark.circle", text: "Why are you seeing this")
                    buttonStyle(image: "eye.slash", text: "Not interested")
                }
            }
        }
        
    }

    private func buttonStyle(image: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: image)
            Text(text)
        }
        .font(.system(size: 18))
        .padding(.vertical, 8)
    }
}

#Preview {
    PostActionView(post: PostModel(user: User.placeholder, caption: "", mediaType: .image))
}
