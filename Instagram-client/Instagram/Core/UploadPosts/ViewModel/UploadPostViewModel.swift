//
//  UploadPostViewModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 09/04/25.
//

import SwiftUI
import Foundation

@MainActor
class UploadPostViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    @Published var caption: String = ""
    @Published var isUploading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var showPicker: Bool = true

    let postService = PostService()

    func uploadPost(tab: Binding<Int>) {
        guard let image = selectedImage else { return }
        isUploading = true

        Task {
            let success = await postService.uploadPost(image: image, caption: caption)
            isUploading = false

            if success {
                selectedImage = nil
                caption = ""
                tab.wrappedValue = 0
            } else {
                alertMessage = postService.errorMessage ?? "Failed to upload post"
                showAlert = true
            }
        }
    }

    func uploadReel(tab: Binding<Int>) {
        guard let videoURL = selectedVideoURL else { return }
        isUploading = true

        Task {
            let success = await postService.uploadReel(video: videoURL, caption: caption)
            isUploading = false

            if success {
                selectedVideoURL = nil
                caption = ""
                tab.wrappedValue = 0
            } else {
                alertMessage = postService.errorMessage ?? "Failed to upload reel"
                showAlert = true
            }
        }
    }

    func clearSelection() {
        selectedImage = nil
        selectedVideoURL = nil
        showPicker = true
    }
}
