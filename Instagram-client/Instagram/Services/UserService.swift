//
//  UserInfo.swift
//  instagram
//
//  Created by Riptik Jhajhria on 27/03/25.
//
import Foundation
import SwiftUI
import PhotosUI

@MainActor
class UserInfo: ObservableObject {
    @Published var user: User?
    @Published var allUser: [User]?
    
    let httpClient: HTTPClient
    
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(from: selectedImage) } }
    }
    
    @Published var profileImage: Image?
    @Published var username: String
    @Published var fullName: String
    @Published var bio: String
    
    private var uiImage: UIImage?
    private var imageUrlString: String?
    
    init(httpClient: HTTPClient, username: String = "unknown", fullName: String = "unknown", bio: String = "bio Unknown") {
        self.httpClient = httpClient
        self.username = username
        self.fullName = fullName
        self.bio = bio
        Task {
            try? await loadUserInfo(userId: user?.id ?? "")
        }
    }
    
    func updateUserInfo() async throws {
        // Create base user data
        let updatedUserData: [String: Any] = [
            "username": username,
            "fullName": fullName,
            "bio": bio
        ]
        
        // If an image was selected, upload it first
        if let uiImage = uiImage, let imageData = uiImage.jpegData(compressionQuality: 0.8) {
            // Create boundary for multipart form data
            let boundary = UUID().uuidString
            let headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
            
            var body = Data()
            let lineBreak = "\r\n"
            
            // Add text fields
            for (key, value) in updatedUserData {
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
                body.append("\(value)\(lineBreak)".data(using: .utf8)!)
            }
            
            // Add image file
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profileImage\"; filename=\"image.jpg\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            body.append(imageData)
            body.append("\(lineBreak)".data(using: .utf8)!)
            body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
            
            // Create and send request
            let resource = Resource(
                url: Constants.URLs.uploadProfileImage,
                method: .put(body),
                headers: headers,
                modelType: UserResponse.self
            )
            
            let response = try await httpClient.load(resource)
            
            if let userInfo = response.userInfo, response.success {
                self.user = userInfo
            } else {
                print("❌ Failed to update user info")
            }
        } else {
            // If no image, just update the text fields
            let jsonData = try JSONEncoder().encode([
                "username": username,
                "fullName": fullName,
                "bio": bio
            ])
            
            let resource = Resource(
                url: Constants.URLs.uploadProfileImage,
                method: .put(jsonData),
                modelType: UserResponse.self
            )
            
            let response = try await httpClient.load(resource)
            
            if let userInfo = response.userInfo, response.success {
                self.user = userInfo
            } else {
                print("❌ Failed to update user info")
            }
        }
        
        // Reload user data to get updated information including new profile image URL
//        try await loadUserInfo(userId: user?.id ?? "")
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func loadAllUser() async throws {
        let resource = Resource(url: Constants.URLs.loadAllUser, modelType: AllUsersResponse.self)
        let response = try await httpClient.load(resource)
        if response.success {
            allUser = response.users ?? []
        }
    }
    
    func loadUserInfo(userId: String) async throws {
        let resource = Resource(
            url: Constants.URLs.loadUserById(userId),
            modelType: UserResponse.self
        )
        
        let response = try await httpClient.load(resource)
        
        if let userInfo = response.userInfo, response.success {
                DispatchQueue.main.async {
                    self.username = userInfo.username
                    self.fullName = userInfo.fullName ?? ""
                    self.bio = userInfo.bio ?? ""
                    self.imageUrlString = userInfo.profileImage
                    self.user = userInfo
                    self.objectWillChange.send()
                }
            
            if let imageUrlString = userInfo.profileImage, let url = URL(string: imageUrlString) {
                await loadImageFromURL(url)
            }
        }
    }
    
    func loadImage(from item: PhotosPickerItem?) async { 
        guard let item = item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.profileImage = Image(uiImage: uiImage)
    }
    
    private func loadImageFromURL(_ url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = Image(uiImage: uiImage)
                    self.objectWillChange.send()
                }
            }
        } catch {
            print("❌ Error loading image from URL: \(error)")
        }
    }
    
    func followUser(userIdToFollow: String) async throws -> FollowResponse {
        let requestBody = FollowRequest(userIdToFollow: userIdToFollow)
        let bodyData = try JSONEncoder().encode(requestBody)

        let resource = Resource<FollowResponse>(
            url: Constants.URLs.follow,
            method: .post(bodyData),
            modelType: FollowResponse.self
        )

        return try await httpClient.load(resource)
    }
    
}
