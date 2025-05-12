//
//  AuthViewModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 04/04/25.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorState: (showError: Bool, errorMessage: String) = (false, "Uh Oh")
    @AppStorage("token") var token: String?
    @AppStorage("userId") var userId: String?
    
    private let authController = AuthController(httpClient: .development)
    
    var disableButton: Bool { !email.isEmptyOrWhitespace && !password.isEmptyOrWhitespace }
    
    func signup() async {
        do {
            let response = try await authController.signup(username: username, email: email, password: password)
            if response.success, response.result?.id != nil {
                self.userId = response.result?.id
            } else {
                errorState.errorMessage = response.message ?? ""
            }
            
            
            
        } catch {
            print("Error in signup: \(error.localizedDescription)")
            errorState.errorMessage = "Failed to creeate an account \(error.localizedDescription)"
            errorState.showError = true
        }
        
        username = ""
        password = ""
    }
    
    func signin() async {
        do {
            let response = try await authController.signin(email: email, password: password)
            guard let token = response.token,
                  let userId = response.userId,
                  response.success else {
                errorState.showError = true
                errorState.errorMessage = response.message ?? "Something went wrong"
                return
            }
           
            self.userId = userId
            Keychain.set(token, forKey: "jwttoken")
            self.token = token
            email = ""
            password = ""
            print(" UserId: \(userId)")
        } catch {
            print("Error in signin: \(error.localizedDescription)")
            errorState.errorMessage = "Failed to creeate an account \(error.localizedDescription)"
            errorState.showError = true
        }
    }
}
