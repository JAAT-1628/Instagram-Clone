//
//  MainTabView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 26/02/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    let user: User?
    init(user: User? = nil) {
        self.user = user
        makeTabBarOpaque()
    }
    
    @StateObject private var postService = PostService(httpClient: .development)
    @State private var userinfo = UserInfo(httpClient: HTTPClient())
    @AppStorage("token") var token: String?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("", image: "home", value: 0) {
                FeedView(selectedTab: $selectedTab)
            }
            Tab("", image: "search", value: 1) {
                SearchView()
            }
            Tab("", image: "plus", value: 2) {
                UploadPostView(tab: $selectedTab)
            }
            Tab("", image: "reel", value: 3) {
                ReelView()
                    .edgesIgnoringSafeArea(.top)
            }
            Tab("", image: "profile", value: 4) {
                CurrentUsersProfileView()
                    .onAppear {
                        Task {
                            if token != nil {
                                await loadUserInfo()
                            }
                        }
                    }
            }
        }
    }
    private func loadUserInfo() async {
        do {
            try await userinfo.loadUserInfo(userId: userinfo.user?.id ?? "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func makeTabBarOpaque() {
        let apperance = UITabBarAppearance()
        apperance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = apperance
        UITabBar.appearance().scrollEdgeAppearance = apperance
    }
}

#Preview {
    MainTabView()
}
