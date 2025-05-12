//
//  UploadPostView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI
import PhotosUI

struct UploadPostView: View {
    @StateObject private var viewModel = UploadPostViewModel()
    @Binding var tab: Int

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack {
                    headerView()
                    mediaPreview()
                    Spacer()
                }
                .toolbar(.hidden, for: .tabBar)
                .sheet(isPresented: $viewModel.showPicker) {
                    MediaPicker(selectedImage: $viewModel.selectedImage, selectedVideoURL: $viewModel.selectedVideoURL)
                        .presentationDetents([.fraction(0.6), .large])
                }
            }

            if viewModel.selectedImage != nil || viewModel.selectedVideoURL != nil {
                Button {
                    if viewModel.selectedVideoURL != nil {
                        viewModel.uploadReel(tab: $tab)
                    } else {
                        viewModel.uploadPost(tab: $tab)
                    }
                } label: {
                    if viewModel.isUploading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Share")
                    }
                }
                .modifier(ButtonModifier())
                .padding()
                .disabled(viewModel.isUploading)
            } else {
                if !viewModel.showPicker {
                    Button {
                        viewModel.showPicker = true
                    } label: {
                        Text("Select")
                            .modifier(ButtonModifier())
                            .padding()
                    }
                    .padding(.top, 100)
                }
            }

            Text("Reels made with Edits are optimized for high-quality playback on Instagram.")
                .font(.footnote)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .animation(.spring, value: viewModel.showPicker)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Upload Status"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func mediaPreview() -> some View {
        VStack {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(alignment: .topLeading) { clearButton }
                optionsView()
            } else if let url = viewModel.selectedVideoURL {
                VideoThumbnailView(videoUrl: url)
                    .scaledToFit()
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topLeading) { clearButton }
                optionsView()
            } else {
                Text("Select image or video to post")
                    .padding(.vertical, 50)
            }
        }
        .padding(.top)
    }

    private var clearButton: some View {
        Image(systemName: "xmark")
            .imageScale(.large)
            .padding(2)
            .background(.gray.opacity(0.4))
            .cornerRadius(20)
            .padding(6)
            .onTapGesture {
                viewModel.clearSelection()
            }
    }

    private func optionsView() -> some View {
        VStack {
            TextField("Add a caption...", text: $viewModel.caption, axis: .vertical)
                .lineLimit(20)
                .padding(.top, 15)
                .padding(.horizontal)

            HStack(spacing: 10) {
                Label("Pool", systemImage: "line.3.horizontal")
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                Label("Prompt", systemImage: "message")
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            labelButtons("Tag People", icon: "person.crop.square")
            labelButtons("Add Location", icon: "location.north")
            labelButtons("Music", icon: "music.note")
        }
    }

    private func labelButtons(_ title: String, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 20, height: 20)
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private func headerView() -> some View {
        HStack {
            Button {
                tab = 0
            } label: {
                Image(systemName: "xmark")
                    .imageScale(.large)
            }
            Spacer()
            Text("New post")
            Spacer()
            if viewModel.selectedImage != nil || viewModel.selectedVideoURL != nil {
                Button {
                    if viewModel.selectedVideoURL != nil {
                        viewModel.uploadReel(tab: $tab)
                    } else {
                        viewModel.uploadPost(tab: $tab)
                    }
                } label: {
                    Text("Post")
                        .foregroundStyle(.blue)
                }
                .disabled(viewModel.isUploading)
            } else {
                Text("Post")
                    .foregroundStyle(.blue.opacity(0.5))
            }
        }
        .font(.subheadline)
        .padding(.horizontal)
    }
}

#Preview {
    UploadPostView(tab: .constant(0))
}
