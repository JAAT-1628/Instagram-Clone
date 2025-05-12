//
//  Constants.swift
//  Amazon
//
//  Created by Riptik Jhajhria on 23/03/25.
//

import Foundation

struct Constants {
     
    struct URLs {
        static let signup: URL = URL(string: "http://localhost:8000/api/auth/signup")!
        static let signin: URL = URL(string: "http://localhost:8000/api/auth/signin")!
        static let loadUserInfo: URL = URL(string: "http://localhost:8000/api/user")!
        static let loadAllUser: URL = URL(string: "http://localhost:8000/api/user/get-all-user")!
        static let uploadProfileImage: URL = URL(string: "http://localhost:8000/api/user/upload-profile-image")!
        static let uploadPost: URL = URL(string: "http://localhost:8000/api/post")!
        static let getAllPosts: URL = URL(string: "http://localhost:8000/api/post")!
        static let follow: URL = URL(string: "http://localhost:8000/api/user/follow")!
        static let uploadReel: URL = URL(string: "http://localhost:8000/api/post/reel")!
        static let getAllReels: URL = URL(string: "http://localhost:8000/api/post/reels")!
        static let fetchChats: URL = URL(string: "http://localhost:8000/api/chat/list")!
        static let startChat: URL = URL(string: "http://localhost:8000/api/chat/start")!
        
        static func getNotification(_ userId: String) -> URL {
            URL(string: "http://localhost:8000/api/notification/\(userId)")!
        }
        
        static func getMyPosts(_ userId: String) -> URL {
            URL(string: "http://localhost:8000/api/post/user/\(userId)")!
        }
        
        static func likeAPost(_ postId: String) -> URL {
            URL(string: "http://localhost:8000/api/post/like/\(postId)")!
        }
        
        static func addComment(_ postId: String) -> URL {
            URL(string: "http://localhost:8000/api/post/comment/\(postId)")!
        }
        
        static func loadUserById(_ userId: String) -> URL {
            URL(string: "http://localhost:8000/api/user/\(userId)")!
        }
        
        static func getUserWithFollowInfo(_ userId: String) -> URL {
            URL(string: "http://localhost:8000/api/user/\(userId)/follow-info")!
        }
        
        static func getPostById(_ id: String) -> URL {
            URL(string: "http://localhost:8000/api/post/\(id)")!
        }
        
        static func deletePost(_ postId: String) -> URL {
            URL(string: "http://localhost:8000/api/post/\(postId)")!
        }
        
        static func fetchMessages(from user1: String, to user2: String) -> URL {
            URL(string: "http://localhost:8000/api/messages/\(user1)/\(user2)")!
        }
        
        static func markChatAsRead(chatId: String) -> URL {
            return URL(string: "http://localhost:8000/api/chat/\(chatId)/read")!
        }
    }
}
