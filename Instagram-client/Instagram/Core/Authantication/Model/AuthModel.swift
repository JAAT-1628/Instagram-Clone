//
//  AuthModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 02/03/25.
//

import Foundation

struct SignupResponse: Codable {
    let message: String?
    let success: Bool
    let result: User?
}

struct SigninResponse: Codable {
    let message: String?
    let success: Bool
    let token: String?
    let userId: String?
}

struct ErrorResponse: Codable {
    let message: String?
    let success: Bool
}
