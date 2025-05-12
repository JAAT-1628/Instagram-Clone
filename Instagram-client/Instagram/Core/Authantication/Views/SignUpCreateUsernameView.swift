//
//  SignUpCreateUsernameView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI

struct SignUpCreateUsernameView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: AuthViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Create Username")
                .font(.title3)
            Text("Create a username for your account the username will be shown as your profile name")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.gray)
                .padding(.bottom, 30)
            TextField("Username", text: $vm.username)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
                .padding(.bottom)
            NavigationLink {
                SignUpPasswordView(vm: vm)
                    .navigationBarBackButtonHidden(true)
            } label: {
                Text("Next")
                    .modifier(ButtonModifier())
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
        .padding(.horizontal)
        Spacer()
    }
}

#Preview {
//    SignUpCreateUsernameView()
}
