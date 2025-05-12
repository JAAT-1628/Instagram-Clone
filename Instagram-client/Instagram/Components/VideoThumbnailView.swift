//
//  VideoThumbnailView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 09/04/25.
//

import SwiftUI
import AVFoundation


struct VideoThumbnailView: View {
    
    let videoUrl: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Color.gray // Placeholder
            }
        }
        .onAppear {
            generateThumbnail(from: videoUrl) { image in
                self.thumbnail = image
            }
        }
    }

    func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 0.0, preferredTimescale: 600)

        imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
            if let cgImage = cgImage {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    completion(uiImage)
                }
            } else {
                print("Thumbnail generation failed: \(String(describing: error))")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}


#Preview {
    VideoThumbnailView(videoUrl: URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!)
}
