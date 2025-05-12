//
//  SignUpPasswordView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI

struct SignUpPasswordView: View {
    @ObservedObject var vm: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isSecureField = true
    @State private var isLoading = false
    @State private var navigateToLogin = false
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Create a password")
                .font(.title3)
            Text("your password must be at least 8 characters in length")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.gray)
                .padding(.bottom, 30)
            HStack {
                if isSecureField {
                    SecureField("Password", text: $vm.password)
                        .autocapitalization(.none)
                } else {
                    TextField("Password", text: $vm.password)
                        .autocapitalization(.none)
                }
                Button {
                    isSecureField.toggle()
                } label: {
                    if isSecureField {
                        Image(systemName: "eye")
                    } else {
                        Image(systemName: "eye.slash")
                    }
                }
            }
            .modifier(TextFieldModifier())
            .padding(.bottom)
            Button {
                Task {
                    isLoading = true
                    await vm.signup()
                    isLoading = false
                    
                    // If account creation was successful, navigate back to login
                    if vm.errorState.showError && vm.errorState.errorMessage.contains("successfully") {
                        navigateToLogin = true
                    }
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .modifier(ButtonModifier())
                } else {
                    Text("Create Account")
                        .modifier(ButtonModifier())
                }
            }
            .disabled(vm.password.count < 8 || isLoading)
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
        .alert(isPresented: $vm.errorState.showError) {
            Alert(
                title: Text("Message"),
                message: Text(vm.errorState.errorMessage),
                dismissButton: .default(Text("OK")) {
                    if vm.errorState.errorMessage.contains("successfully") {
                        // Navigate back to login after successful signup
                        navigateToLogin = true
                    }
                }
            )
        }
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginView()
                .navigationBarBackButtonHidden(true)
        }
        Spacer()
    }
}

#Preview {
    NavigationStack {
        SignUpPasswordView(vm: AuthViewModel())
    }
}
