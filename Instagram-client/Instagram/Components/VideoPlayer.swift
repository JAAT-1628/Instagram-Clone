//
//  VideoPlayer.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 09/04/25.
//

import SwiftUI
import AVKit

struct AutoVideoPlayer: View {
    let url: URL
       @State private var player = AVPlayer()
       @State private var isMuted: Bool = true
       @State private var isReady = false
       @State private var isVisible = false
       @State private var videoAspectRatio: CGFloat = 16/9 // Default, will be updated
       
       var body: some View {
           GeometryReader { outerProxy in
               ZStack {
                   GeometryReader { geo in
                       VideoPlayer(player: player)
                           .frame(width: geo.size.width, height: geo.size.width / videoAspectRatio)
                           .clipped()
                           .onChange(of: isVisible) { oldValue, newValue in
                               if newValue {
                                   player.play()
                               } else {
                                   player.pause()
                               }
                           }
                           .onAppear {
                               setupPlayer()
                           }
                           .onDisappear {
                               player.pause()
                           }
                           .background(
                               Color.clear
                                   .onAppear { updateVisibility(frame: geo.frame(in: .global), screen: outerProxy.size) }
                                   .onChange(of: geo.frame(in: .global)) { oldFrame, newFrame in
                                       updateVisibility(frame: newFrame, screen: outerProxy.size)
                                   }
                           )
                   }
                   
                   // Mute Button
                   VStack {
                       Spacer()
                       HStack {
                           Spacer()
                           Button(action: {
                               isMuted.toggle()
                               player.isMuted = isMuted
                           }) {
                               Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                   .foregroundColor(.white)
                                   .padding(2)
                                   .scaleEffect(0.8)
                                   .background(Color.black.opacity(0.5))
                                   .clipShape(Circle())
                                   .padding()
                           }
                       }
                   }
                   
                   // Loader
                   if !isReady {
                       Color.black.opacity(0.5)
                       ProgressView()
                           .progressViewStyle(CircularProgressViewStyle(tint: .white))
                           .scaleEffect(1.5)
                   }
               }
           }
           .aspectRatio(videoAspectRatio, contentMode: .fit)
       }
       
       private func updateVisibility(frame: CGRect, screen: CGSize) {
           let midY = frame.midY
           let screenMidY = screen.height / 2
           let isNowVisible = abs(midY - screenMidY) < 200 // adjust tolerance as needed
           if isVisible != isNowVisible {
               isVisible = isNowVisible
           }
       }
       
       private func setupPlayer() {
           let item = AVPlayerItem(url: url)
           player.replaceCurrentItem(with: item)
           player.isMuted = isMuted
           player.actionAtItemEnd = .none
           
           // Get video dimensions to determine aspect ratio
           let asset = item.asset
           
           // Using the newer async APIs for iOS 16.0+
           Task {
               do {
                   // Load video tracks
                   let videoTracks = try await asset.loadTracks(withMediaType: .video)
                   
                   if let videoTrack = videoTracks.first {
                       // Load naturalSize and preferredTransform
                       let naturalSize = try await videoTrack.load(.naturalSize)
                       let preferredTransform = try await videoTrack.load(.preferredTransform)
                       
                       let size = naturalSize.applying(preferredTransform)
                       let width = abs(size.width)
                       let height = abs(size.height)
                       
                       // Update aspect ratio (width / height)
                       if height > 0 {
                           await MainActor.run {
                               self.videoAspectRatio = width / height
                           }
                       }
                   }
               } catch {
                   print("Error loading video track information: \(error)")
               }
           }
           
           NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
               player.seek(to: .zero)
               player.play()
           }
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
               isReady = true
           }
       }
   }

#Preview {
    AutoVideoPlayer(url: URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!)
}
