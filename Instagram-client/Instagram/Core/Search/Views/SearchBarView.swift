//
//  SearchBarView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI

struct SearchBarView: View {
    var animation: Namespace.ID
    @State private var search = ""
    @Binding var dismissSearch: Bool
    @FocusState var focusSearch: Bool
    @StateObject private var userInfo = UserInfo(httpClient: .development)
    
    var body: some View {
        NavigationStack {
            searchBar()
                .padding(.horizontal)
                .padding(.bottom)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if search.isEmpty {
                        Text("Search for user by their username")
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(userInfo.allUser?.filter {
                            let isNotCurrentUser = $0.id != UserDefaults.standard.string(forKey: "userId")
                            let matchesSearch = $0.username.lowercased().contains(search.lowercased())
                            return isNotCurrentUser && matchesSearch
                        } ?? []) { users in
                            NavigationLink(value: users) {
                                HStack {
                                    CircularProfileImageView(urlString: users.profileImage, size: .xSmall)
                                    VStack(alignment: .leading) {
                                        Text(users.username)
                                        if let fullName = users.fullName {
                                            Text(fullName)
                                                .lineLimit(1)
                                                .font(.footnote)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        focusSearch = true
                    }
                }
            }
            .navigationDestination(for: User.self) { user in
                ProfileView(user: user)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .task {
            try? await userInfo.loadAllUser()
        }
    }
    @ViewBuilder
    private func searchBar() -> some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .imageScale(.medium)
                    .foregroundStyle(.gray)
                TextField("search", text: $search)
                    .focused($focusSearch)
                    .textCase(.lowercase)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.gray.opacity(0.7), lineWidth: 1)
            )
            Button("cancel") { withAnimation(.easeInOut) { dismissSearch = false } }
        }
        .padding(.top, 8)
    }
}

#Preview {
    //    SearchBarView()
    SearchView()
}
