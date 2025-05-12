//
//  OptionsView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 03/03/25.
//

import SwiftUI

struct OptionsView: View {
    @AppStorage("token") var token: String?
    @AppStorage("userId") var userId: String?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    accountView()
                } header: {
                    HStack {
                        Text("Your account")
                        Spacer()
                        Text("Meta")
                    }
                    .textCase(nil)
                    .bold()
                }
                
                Section {
                    buttons(icon: "bookmark", title: "Saved")
                    buttons(icon: "archivebox", title: "Archive")
                    buttons(icon: "chart.xyaxis.line", title: "Your activity")
                    buttons(icon: "bell", title: "Notification")
                    buttons(icon: "clock.arrow.circlepath", title: "Time managment")
                } header: {
                    Text("How you use Instagram")
                        .bold()
                        .textCase(nil)
                }
                
                Section {
                    buttons(icon: "lock", title: "Account Privacy")
                    buttons(icon: "star.circle", title: "Close Friends")
                    buttons(icon: "square.grid.2x2", title: "Crossposting")
                    buttons(icon: "hand.raised.slash", title: "Blocked")
                    buttons(icon: "circle.slash", title: "Hide story and live")
                } header: {
                    Text("Who can see your content")
                        .bold()
                        .textCase(nil)
                }
                Section {
                    buttons(icon: "ellipsis.message", title: "Messages and story reply")
                    buttons(icon: "at", title: "Tags and mentions")
                    buttons(icon: "message", title: "Comments")
                    buttons(icon: "square.and.arrow.up", title: "Sharing")
                    buttons(icon: "person.slash", title: "Restricted")
                    buttons(icon: "circle.badge.questionmark", title: "Limited interaction")
                    buttons(icon: "keyboard", title: "Hidden words")
                    buttons(icon: "person.badge.plus", title: "Follow and invite Friends")
                } header: {
                    Text("How others can interact with you")
                        .bold()
                        .textCase(nil)
                }
                
                Section {
                    loginSection()
                } header: {
                    Text("Login")
                        .bold()
                        .textCase(nil)
                }
            }
            .navigationTitle("Settings and activity")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.grouped)
        }
    }
    
    private func loginSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add account")
                .foregroundStyle(.blue.opacity(0.6))
            Text("Log out")
                .foregroundStyle(.red)
                .onTapGesture {
                   let _ = Keychain<String>.delete("jwttoken")
                    token = nil
                    userId = nil
                }
        }
    }
    
    private func accountView() -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading) {
                    Text("Accounts centre")
                        .font(.subheadline)
                    Text("password, sequerty, personal details")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
            Text("Manage your connected experience and account settings across Meta techonologies. ").font(.footnote) +
            Text("Learn more.")
                .font(.footnote)
                .bold()
                .foregroundStyle(.blue)
        }
    }
    private func buttons(icon: String, title: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .imageScale(.large)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .font(.subheadline)
    }
}

#Preview {
    OptionsView()
}
