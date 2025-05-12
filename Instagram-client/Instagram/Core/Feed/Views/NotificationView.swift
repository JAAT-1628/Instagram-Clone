//
//  NotificationView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 11/04/25.
//

import SwiftUI
import Kingfisher

struct NotificationView: View {
    @StateObject private var service = NotificationService()
      @AppStorage("userId") private var userId: String?
      @Environment(\.dismiss) private var dismiss
      let user: User

      var body: some View {
          List {
              if service.notifications.isEmpty {
                  Text("No notifications yet")
                      .foregroundColor(.gray)
                      .frame(maxWidth: .infinity, alignment: .center)
                      .padding()
              } else {
                  ForEach(groupedNotifications.keys.sorted(by: >), id: \ .self) { key in
                      Section(header: Text(key).font(.headline)) {
                          ForEach(groupedNotifications[key] ?? []) { notif in
                              notificationRow(for: notif)
                          }
                      }
                  }
              }
          }
          .listStyle(.grouped)
          .onAppear {
              Task {
                  if let userId = userId {
                      await service.fetchNotifications(for: userId)
                      setupSocketConnection(userId: userId)
                  }
              }
          }
          .onDisappear {
              RealTimeNotificationManager.shared.disconnect()
          }
          .hideNavBarOnSwipe(false)
          .toolbar {
              ToolbarItem(placement: .topBarLeading) {
                  Button {
                      dismiss()
                  } label: {
                      Label("\(user.username)", systemImage: "chevron.backward")
                  }
              }
          }
      }

      private func setupSocketConnection(userId: String) {
          RealTimeNotificationManager.shared.connect(userId: userId) { newNotif in
              DispatchQueue.main.async {
                  if !service.notifications.contains(where: { $0.id == newNotif.id }) {
                      service.notifications.insert(newNotif, at: 0)
                  }
              }
          }
      }

      private func message(for type: NotificationType) -> String {
          switch type {
          case .like: return "liked your post"
          case .comment: return "commented on your post"
          case .follow: return "started following you"
          }
      }

      private var groupedNotifications: [String: [NotificationModel]] {
          Dictionary(grouping: service.notifications) { $0.createdAt.sectionHeader }
      }

      @ViewBuilder
      private func notificationRow(for notif: NotificationModel) -> some View {
          HStack {
              CircularProfileImageView(urlString: notif.fromUser.profileImage, size: .xSmall)
              VStack(alignment: .leading) {
                  Text("\(notif.fromUser.username)    ").foregroundStyle(.gray) +
                  Text("\(message(for: notif.type))")
                      .font(.subheadline)
                  Text(notif.createdAt.TimeAgoSinceNow())
                      .font(.caption)
                      .foregroundColor(.gray)
              }
              Spacer()
              if let post = notif.post,
                 let imageURL = URL(string: post.imageUrl ?? "") {
                  KFImage(imageURL)
                      .resizable()
                      .frame(width: 40, height: 40)
                      .cornerRadius(6)
              }
          }
      }
  }

#Preview {
    NotificationView(user: .placeholder)
}
