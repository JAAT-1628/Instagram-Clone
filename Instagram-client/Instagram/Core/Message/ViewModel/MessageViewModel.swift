//
//  MessageViewModel.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 12/04/25.
//

import Foundation
import SwiftUI

@MainActor
class MessageViewModel: ObservableObject {
    @Published var followingUsers: [User] = []
    @Published var isLoading = true
    @Published var currentUser: User
    @Published var searchText = ""
    
    private let profileVM = ProfileViewModel()
    private let userInfo = UserInfo(httpClient: .development)
    private let chatVM: ChatViewModel
    
    init(currentUser: User) {
        self.currentUser = currentUser
        self.chatVM = ChatViewModel(currentUser: currentUser)
    }
    
    func loadData() async {
        guard let userId = currentUser.id else { return }
        isLoading = true
        
        // Load data concurrently
        async let userFetch: () = profileVM.fetchUser(userId: userId)
        async let allUsersFetch: () = userInfo.loadAllUser()
        async let chatsFetch: () = fetchChats()
        
        do {
            // Wait for all operations to complete
            await userFetch
            try await allUsersFetch
            try await chatsFetch
            
            // Update current user if available
            if let updatedUser = profileVM.currentUser {
                self.currentUser = updatedUser
            }
            
            // Update following users
            if let allUsers = userInfo.allUser {
                followingUsers = currentUser.following.compactMap { follow in
                    guard let followId = follow.id else { return nil }
                    return allUsers.first(where: { $0.id == followId })
                }
            }
            
            // Hide loading indicator
            isLoading = false
        } catch {
            print("Error loading data: \(error)")
            isLoading = false
        }
    }
    
    private func fetchChats() async throws {
        try await chatVM.fetchChats()
    }
    
    var filteredFollowingUsers: [User] {
        if searchText.isEmpty {
            return followingUsers
        }
        return followingUsers.filter { user in
            user.username.lowercased().contains(searchText.lowercased())
        }
    }
    
    var filteredChats: [Chat] {
        chatVM.filterChats(with: searchText)
    }
    
    func getOtherParticipant(in chat: Chat) -> User? {
        chatVM.getOtherParticipant(in: chat)
    }
} 
