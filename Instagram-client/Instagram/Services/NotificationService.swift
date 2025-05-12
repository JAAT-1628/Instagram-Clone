//
//  NotificationService.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 11/04/25.
//

import Foundation

@MainActor
class NotificationService: ObservableObject {
    @Published var notifications: [NotificationModel] = []
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient = .development) {
        self.httpClient = httpClient
    }
    
    func fetchNotifications(for userId: String) async {
        do {
            let resourse = Resource(url: Constants.URLs.getNotification(userId), modelType: [NotificationModel].self)
            let response = try await httpClient.load(resourse)
            DispatchQueue.main.async {
                self.notifications = response
            }
        } catch {
            print("Failed to load notifications:", error)
        }
    }
}

