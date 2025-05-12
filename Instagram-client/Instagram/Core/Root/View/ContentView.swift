//
//  ContentView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 26/02/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isSplashScreen = true
    @State private var isLoading = true
    @AppStorage("userId") var userId: String?
   
    var body: some View {
        Group {
            if isSplashScreen {
                splashScreen()
            } else {
                MainTabView()
                    .requiresAuthantication()
            }
        } .onAppear {
            checkAuthentication()
            if let userId {
                ChatService.shared.setUserId(userId)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isSplashScreen = false
                }
            }
        }
    }
    private func checkAuthentication() {
        guard let token = Keychain<String>.get("jwttoken"), JWTTokenValidator.validate(token: token) else {
            isLoading = false
            return
        }
        isLoading = false
    }
    private func splashScreen() -> some View {
        VStack {
            Spacer()
            Image("icon")
                .resizable()
                .frame(width: 60, height: 60)
            
            Spacer()
            Text("From")
                .font(.footnote)
                .foregroundStyle(.gray)
            Text("JAAT")
                .font(.subheadline)
                .bold()
        }
        .opacity(isSplashScreen ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: isSplashScreen)
    }
}

#Preview {
    ContentView()
}
