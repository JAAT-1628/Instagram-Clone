//
//  UserModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 05/04/25.
//

import Foundation


struct User: Identifiable, Hashable {
    var id: String?
    var username: String
    var bio: String?
    var fullName: String?
    var profileImage: String?
    
    var followers: [FollowUser]
    var following: [FollowUser]
    
    static let placeholder = User(
        username: "name",
        bio: "nobio",
        fullName: "dddd",
        profileImage: "mustang",
        followers: [],
        following: []
    )
}

// Extend User to conform to Decodable
extension User: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username, fullName, bio, profileImage
        case followers, following
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        
        // Handle followers - could be array of strings or array of objects
        if let followersArray = try? container.decode([FollowUser].self, forKey: .followers) {
            followers = followersArray
        } else if let followerIds = try? container.decode([String].self, forKey: .followers) {
            followers = followerIds.map { FollowUser(id: $0, username: nil, profileImage: nil) }
        } else {
            followers = []
        }
        
        // Handle following - could be array of strings or array of objects
        if let followingArray = try? container.decode([FollowUser].self, forKey: .following) {
            following = followingArray
        } else if let followingIds = try? container.decode([String].self, forKey: .following) {
            following = followingIds.map { FollowUser(id: $0, username: nil, profileImage: nil) }
        } else {
            following = []
        }
    }
}

// Extend User to conform to Encodable
extension User: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(fullName, forKey: .fullName)
        try container.encodeIfPresent(profileImage, forKey: .profileImage)
        try container.encode(followers, forKey: .followers)
        try container.encode(following, forKey: .following)
    }
}

struct FollowUser: Codable, Identifiable, Hashable {
    var id: String?
    var username: String?
    var profileImage: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username, profileImage
    }
}

struct UserResponse: Codable {
    let message: String?
       let success: Bool
       let userInfo: User?
       let user: User?
       
       // This ensures we get the user regardless of which field the API uses
       var effectiveUser: User? {
           return userInfo ?? user
       }
}

struct AllUsersResponse: Codable {
    let success: Bool
    let users: [User]?
}

struct UploadDataResponse: Codable {
    let message: String?
    let success: Bool
    let downloadURL: URL?

    private enum CodingKeys: String, CodingKey {
        case message, success
        case downloadURL = "profileImage"
    }
}

struct FollowRequest: Codable {
    let userIdToFollow: String
}

struct FollowResponse: Codable {
    let message: String?
    let success: Bool
}
