//
//  EditProfileView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 05/03/25.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userInfo = UserInfo(httpClient: HTTPClient())
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .imageScale(.large)
                }
                Spacer()
                Button {
                    Task { try await userInfo.updateUserInfo() }
                    dismiss()
                } label: {
                    Text("Done")
                        .foregroundStyle(.blue)
                }
            }
            
            PhotosPicker(selection: $userInfo.selectedImage) {
                profileImageSection()
            }
            
            HStack {
                Text("Username ")
                TextField("Username", text: $userInfo.username)
                    .padding(6)
                    .padding(.horizontal, 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(lineWidth: 0.6)
                    }
            }
            HStack {
                Text("Full Name ")
                TextField("Fullname", text: $userInfo.fullName)
                    .padding(6)
                    .padding(.horizontal, 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(lineWidth: 0.6)
                    }
            }
            HStack(spacing: 60) {
                Text("Bio ")
                TextField("Bio", text: $userInfo.bio)
                    .padding(6)
                    .padding(.horizontal, 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(lineWidth: 0.6)
                    }
            }
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Sign in for professional Account")
                Text("Personal information settings")
                Text("Sign up for meta verified")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.blue)
            .padding(.top, 30)
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            Task {
                try? await userInfo.loadUserInfo(userId: userInfo.user?.id ?? "")
            }
        }
    }
    @ViewBuilder
    private func profileImageSection() -> some View {
        VStack {
            if let image = userInfo.profileImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
            } else {
                CircularProfileImageView(urlString: userInfo.user?.profileImage, size: .large)
            }
            
            Text("Edit profile picture")
                .foregroundStyle(.blue)
                .padding(.bottom, 30)
        }
    }
}

#Preview {
    EditProfileView()
}
