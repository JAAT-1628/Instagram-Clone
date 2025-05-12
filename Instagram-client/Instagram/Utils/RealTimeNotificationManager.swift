//
//  RealTimeNotificationManager.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 11/04/25.
//

import Foundation
import SocketIO

class RealTimeNotificationManager {
    static let shared = RealTimeNotificationManager()
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    private init() {
        manager = SocketManager(socketURL: URL(string: "http://localhost:8000")!, config: [.log(true), .compress])
        socket = manager.defaultSocket
    }
    
    func connect(userId: String, onNewNotification: @escaping (NotificationModel) -> Void) {
        socket.on(clientEvent: .connect) { _, _ in
            print("Socket connected")
            self.socket.emit("join", userId)
        }

        socket.on("new-notification") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                  let notification = try? JSONDecoder().decode(NotificationModel.self, from: jsonData) else {
                print("Failed to parse incoming notification")
                return
            }
            DispatchQueue.main.async {
                onNewNotification(notification)
            }
        }

        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }
}
