//
//  SignUpView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: AuthViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Add your email")
                .font(.title3)
            Text("You'll use this email to sign in to your account")
                .font(.footnote)
                .foregroundStyle(.gray)
                .padding(.bottom, 30)
            TextField("Email", text: $vm.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
                .padding(.bottom)
            NavigationLink {
                SignUpCreateUsernameView(vm: vm)
                    .navigationBarBackButtonHidden(true)
            } label: {
                Text("Next")
                    .modifier(ButtonModifier())
            }
            .disabled(!vm.email.contains(".com"))
            .alert(isPresented: $vm.errorState.showError) {
                Alert(
                    title: Text(vm.errorState.errorMessage),
                    dismissButton: .default(Text("Ok"))
                )
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
//    SignUpView()
}
