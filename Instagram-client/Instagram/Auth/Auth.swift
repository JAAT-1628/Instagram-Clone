//
//  Auth.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 04/04/25.
//

import Foundation

struct AuthController {
    let httpClient: HTTPClient
    
    func signup(username: String, email: String, password: String) async throws -> SignupResponse {
        let body = ["username": username, "email": email, "password": password]
        let bodyData = try JSONEncoder().encode(body)
        
        let resourse = Resource(url: Constants.URLs.signup, method: .post(bodyData), modelType: SignupResponse.self)
        let response = try await httpClient.load(resourse)
        
        return response
    }
    
    func signin(email: String, password: String) async throws -> SigninResponse {
        let body = ["email": email, "password": password]
        let bodyData = try JSONEncoder().encode(body)
        
        let resourse = Resource(url: Constants.URLs.signin, method: .post(bodyData), modelType: SigninResponse.self)
        let response = try await httpClient.load(resourse)
        
        return response
    }
}

extension AuthController {
    static var development: AuthController {
        AuthController(httpClient: HTTPClient())
    }
}
