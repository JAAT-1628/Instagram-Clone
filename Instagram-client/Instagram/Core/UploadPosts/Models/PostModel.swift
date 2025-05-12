//
//  PostModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 06/04/25.
//

import Foundation
import SwiftUI

enum MediaType: String, Codable {
    case image
    case video
}

struct PostModel: Codable, Identifiable, Hashable {
    var id: String?
    var user: User
    var caption: String?
    var imageUrl: String?
    var mediaType: MediaType
    var videoUrl: String? //for reels
    // Update likes from Int to [String] (array of user IDs)
    var likes: [String]  // or let likes: [String]? if you want to make it optional
    let date: Date
    var comments: [CommentModel]?
    
    // Add a computed property to get like count
    var likeCount: Int {
        return likes.count
    }
    
    // Add a function to check if current user has liked this post
    func isLikedByUser(userId: String) -> Bool {
        return likes.contains(userId)
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user = "userId"
        case caption
        case imageUrl
        case videoUrl
        case mediaType
        case likes
        case date
        case comments
    }
    
    // Update the decoder to handle the new likes structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        do {
            user = try container.decode(User.self, forKey: .user)
        } catch {
            // Fallback: only userId string received, so create a dummy user
            let userIdString = try container.decode(String.self, forKey: .user)
            user = User(id: userIdString, username: "Unknown", followers: [], following: [])
        }
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)

        // Handle both the old integer likes and new array likes
        if let likesArray = try? container.decode([String].self, forKey: .likes) {
            likes = likesArray
        } else if (try? container.decode(Int.self, forKey: .likes)) != nil {
            // Handle old format - create an empty array with capacity equal to the count
            // This is just a fallback during transition
            likes = []
        } else {
            likes = []
        }
        
        comments = try container.decodeIfPresent([CommentModel].self, forKey: .comments)

        // Same date decoding as before...
        if let dateDouble = try? container.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: dateDouble / 1000)
        } else if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsedDate = formatter.date(from: dateString) {
                date = parsedDate
            } else {
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                date = fallbackFormatter.date(from: dateString) ?? Date()
            }
        } else {
            date = Date()
        }
        mediaType = (try? container.decode(MediaType.self, forKey: .mediaType)) ?? .image
        videoUrl = try? container.decodeIfPresent(String.self, forKey: .videoUrl)
    }

    init(
        user: User,
        caption: String?,
        imageUrl: String = "",
        videoUrl: String? = nil,
        mediaType: MediaType,
        likes: [String] = [],
        date: Date = Date(),
        comments: [CommentModel]? = nil
    ) {
        self.user = user
        self.caption = caption
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
        self.mediaType = mediaType
        self.likes = likes
        self.date = date
        self.comments = comments
    }
}

// Add these response structures to handle like API responses
struct LikePostResponse: Codable {
    let success: Bool
    let message: String
    let likes: Int
    let liked: Bool?  // This indicates if the post was liked or unliked
}

// Comment model to match the schema in backend
struct CommentModel: Codable, Identifiable, Hashable {
    var id: String?
    var userId: String
    let text: String
    let date: Date
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case text
        case date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)

        // Decode userId as full User or fallback to just ID
        if let userObj = try? container.decode(User.self, forKey: .userId) {
            user = userObj
            userId = userObj.id ?? "unknown"
        } else {
            userId = try container.decode(String.self, forKey: .userId)
            user = nil
        }

        // Decode date in flexible format
        if let dateDouble = try? container.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: dateDouble / 1000)
        } else if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = formatter.date(from: dateString) ?? Date()
        } else {
            date = Date()
        }
    }

    init(id: String? = nil, userId: String, text: String, date: Date = Date()) {
        self.id = id
        self.userId = userId
        self.text = text
        self.date = date
    }
}

// Response structures to match backend responses
struct PostListResponse: Codable {
    let success: Bool
    let posts: [PostModel]
}

struct PostResponse: Codable {
    let success: Bool
    let message: String
    let post: PostModel?
}

