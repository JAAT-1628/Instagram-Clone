//
//  MessageModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 12/04/25.
//

import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let chatId: String
    let senderId: String
    let receiverId: String?
    let text: String
    let createdAt: Date
    
}
