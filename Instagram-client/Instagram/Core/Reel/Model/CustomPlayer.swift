//
//  CustomPlayer.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 10/04/25.
//

import Foundation
import AVKit
import SwiftUI

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        
        // Make sure video loops
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        // Start playing immediately
        player.play()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update player if needed
        if uiViewController.player != player {
            uiViewController.player = player
            player.play()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }
    
    class Coordinator: NSObject {
        let player: AVPlayer
        
        init(player: AVPlayer) {
            self.player = player
            super.init()
        }
        
        @objc func playerDidFinishPlaying() {
            // Seek back to beginning and play again for looping
            player.seek(to: .zero)
            player.play()
        }
    }
}
