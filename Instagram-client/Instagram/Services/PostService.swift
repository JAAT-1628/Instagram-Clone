//
//  PostService.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 06/04/25.
//

import Foundation
import SwiftUI

@MainActor
class PostService: ObservableObject {
    let httpClient: HTTPClient
    
    @Published var reels: [PostModel] = []
    @Published var posts: [PostModel] = []
    @Published var userPosts: [PostModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(httpClient: HTTPClient = .development) {
        self.httpClient = httpClient
    }
    
    // upload reel
    func uploadReel(video: URL, caption: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let videoData = try Data(contentsOf: video)

            // Create multipart form body
            let boundary = UUID().uuidString
            var body = Data()

            // Add video file
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"video\"; filename=\"reel.mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)

            // Add caption
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            body.append(caption.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)

            // End boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            // Setup headers and request
            let headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
            let resource = Resource(
                url: Constants.URLs.uploadReel,
                method: .post(body),
                headers: headers,
                modelType: PostResponse.self
            )

            let response = try await httpClient.load(resource)

            if response.success, let reel = response.post {
                self.userPosts.insert(reel, at: 0)
                isLoading = false
                return true
            } else {
                errorMessage = response.message
                isLoading = false
                return false
            }

        } catch {
            errorMessage = "Failed to upload reel: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // load all reels
    func fetchAllReels() async {
        isLoading = true
        errorMessage = nil

        do {
            let resource = Resource(
                url: Constants.URLs.getAllReels,
                modelType: PostListResponse.self
            )
            let response = try await httpClient.load(resource)

            if response.success {
                self.reels = response.posts
            } else {
//                errorMessage = response.message
                print("Error fetching all reels")
            }

        } catch {
            errorMessage = "Failed to load reels: \(error.localizedDescription)"
        }

        isLoading = false
    }
    
    // Load all posts
    func loadAllPosts() async {
        isLoading = true
        errorMessage = nil

        do {
            let resource = Resource(
                url: Constants.URLs.getAllPosts,
                modelType: PostListResponse.self
            )
            let response = try await httpClient.load(resource)
            
            if response.success {
                // First assign posts so we have comment data
                self.posts = response.posts
                
                // Then loop through and fetch users
                for i in self.posts.indices {
                    guard var comments = self.posts[i].comments else { continue }
                    
                    for j in comments.indices {
                        let comment = comments[j]
                        if let user = await self.fetchUser(for: comment) {
                            comments[j].user = user
                        }
                    }
                    self.posts[i].comments = comments
                }
            } else {
                self.errorMessage = "Failed to load posts"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error loading posts: \(error)")
        }

        isLoading = false
    }
    
    // Load posts for a specific user
    func loadUserPosts(userId: String) async {
        isLoading = true
        errorMessage = nil
        print("⚠️ Starting to load posts for userId: \(userId)")

        do {
            let resource = Resource(url: Constants.URLs.getMyPosts(userId), modelType: PostListResponse.self)
            let response = try await httpClient.load(resource)
            
            if response.success {
                self.userPosts = response.posts
                
                for i in self.userPosts.indices {
                    guard var comments = self.userPosts[i].comments else { continue }
                    
                    for j in comments.indices {
                        let comment = comments[j]
                        if let user = await self.fetchUser(for: comment) {
                            comments[j].user = user
                        }
                    }
                    
                    self.userPosts[i].comments = comments
                }
            } else {
                self.errorMessage = "Failed to load user posts"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error loading user posts: \(error)")
        }
        
        isLoading = false
    }
    
    // Upload a new post with image
    func uploadPost(image: UIImage, caption: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Convert UIImage to Data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                self.errorMessage = "Failed to process image"
                isLoading = false
                return false
            }
            
            // 2. Create multipart form data
            let boundary = UUID().uuidString
            var body = Data()
            
            // Add image part
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"post.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            
            // Add caption part
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            body.append(caption.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            
            // End boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            // 3. Create and send request
            let headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
            let resource = Resource(
                url: Constants.URLs.uploadPost,
                method: .post(body),
                headers: headers,
                modelType: PostResponse.self
            )
            
            let response = try await httpClient.load(resource)
            
            if response.success {
                // Add new post to user posts if available
                if let newPost = response.post {
                    self.userPosts.insert(newPost, at: 0)
                }
                isLoading = false
                return true
            } else {
                self.errorMessage = response.message
                isLoading = false
                return false
            }
        } catch let error as NetworkError {
            switch error {
            case .errorResponse(let response):
                self.errorMessage = response.message
            default:
                self.errorMessage = error.localizedDescription
            }
            print("Error uploading post: \(error)")
            isLoading = false
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error uploading post: \(error)")
            isLoading = false
            return false
        }
    }
    
    // Like a post
    func likePost(postId: String) async -> PostModel? {
        do {
            let resource = Resource(
                url: Constants.URLs.likeAPost(postId),
                method: .put(nil),
                modelType: LikePostResponse.self
            )

            let response = try await httpClient.load(resource)

            guard let currentUser = UserDefaults.standard.string(forKey: "userId") else {
                return nil
            }

            if response.success {
                if let index = posts.firstIndex(where: { $0.id == postId }) {
                    // Mutate the existing post directly
                    posts[index].likes = response.liked == true
                        ? Array(Set(posts[index].likes + [currentUser]))
                        : posts[index].likes.filter { $0 != currentUser }

                    return posts[index]
                }
            }
        } catch {
            print("Error liking post: \(error)")
        }

        return nil
    }

    
    func addComment(to postId: String, commentText: String) async -> PostModel? {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return nil }

        // Prepare body data
        let body: [String: Any] = [
            "userId": userId,
            "text": commentText
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            print("Failed to serialize comment data")
            return nil
        }

        let resource = Resource<PostResponse>(
            url: Constants.URLs.addComment(postId),
            method: .post(bodyData),
            modelType: PostResponse.self
        )

        do {
            let response = try await httpClient.load(resource)
            
            if let updatedPost = response.post {
                // Update the local post in the list
                if let index = posts.firstIndex(where: { $0.id == postId }) {
                    posts[index] = updatedPost
                }
                return updatedPost
            } else {
                print("Comment succeeded but post not returned.")
                return nil
            }
        } catch {
            print("Error adding comment: \(error.localizedDescription)")
            return nil
        }
    }
    
//     fetching user for comment view only
    func fetchUser(for comment: CommentModel) async -> User? {

        let resource = Resource<User>(
            url: Constants.URLs.loadUserById(comment.userId),
            modelType: User.self
        )

        do {
            let user = try await httpClient.load(resource)
            
            print("Fetching user for comment from ID: \(comment.userId)")
            print("Fetched user: \(user.username)")
            return user

        } catch {
            print("Failed to fetch user for comment \(String(describing: comment.id)): \(error)")
            return nil
        }
    }
    
    // Delete a post
    func deletePost(postId: String) async -> Bool {
        do {
            let resource = Resource(
                url: Constants.URLs.deletePost(postId),
                method: .delete,
                modelType: PostResponse.self
            )
            
            let response = try await httpClient.load(resource)
            
            if response.success {
                // Remove post from arrays
                posts.removeAll(where: { $0.id == postId })
                userPosts.removeAll(where: { $0.id == postId })
                return true
            } else {
                self.errorMessage = response.message
                return false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error deleting post: \(error)")
            return false
        }
    }
}
