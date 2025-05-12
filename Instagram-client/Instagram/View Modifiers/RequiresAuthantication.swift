//
//  RequiresAuthantication.swift
//  Amazon
//
//  Created by Riptik Jhajhria on 23/03/25.
//

import Foundation
import SwiftUI

struct RequiresAuthantication: ViewModifier {
    @State private var isLoading: Bool = true
    @AppStorage("userId") var userId: String?
    
    func body(content: Content) -> some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else {
                if userId != nil {
                    content
                } else {
                    LoginView()
                }
            }
        }
        .onAppear(perform: checkAuthentication)
    }
    
    private func checkAuthentication() {
        guard let token = Keychain<String>.get("jwttoken"), JWTTokenValidator.validate(token: token) else {
            userId = nil
            isLoading = false
            return
        }
        isLoading = false
    }
}

extension View {
    func requiresAuthantication() -> some View {
        modifier(RequiresAuthantication())
    }
}
