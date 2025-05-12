//
//  NotificationModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 11/04/25.
//

import Foundation

enum NotificationType: String, Codable {
    case like, comment, follow
}

struct NotificationModel: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let fromUser: User
    let post: PostModel?
    let createdAt: Date
}
