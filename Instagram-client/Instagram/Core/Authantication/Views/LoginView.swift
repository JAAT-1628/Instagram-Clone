//
//  LoginView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image("logo")
                    .resizable()
                    .frame(width: 250, height: 90)
                loginTextFields()
                    .padding(.bottom)
                Button {
                    Task {
                        isLoading = true
                        await vm.signin()
                        isLoading = false
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .modifier(ButtonModifier())
                    } else {
                        Text("Log In")
                            .modifier(ButtonModifier())
                    }
                }
                .disabled(!vm.disableButton || isLoading)
                .padding(.bottom)
                HStack {
                    Rectangle()
                        .frame(height: 0.5)
                    Text("OR")
                        .font(.footnote)
                    Rectangle()
                        .frame(height: 0.5)
                }
                Button {
                    // Facebook login logic would go here
                } label: {
                    HStack {
                        Image("facebook")
                        Text("Continue with facebook")
                    }
                    .foregroundStyle(.blue)
                    .font(.subheadline)
                }

                Spacer()
                
                NavigationLink {
                    SignUpView(vm: vm)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    Text("Don't have an account? ") +
                    Text("Sign Up")
                        .bold()
                }
                .foregroundStyle(.blue)
                .font(.subheadline)
            }
            .padding()
            .alert(isPresented: $vm.errorState.showError) {
                Alert(
                    title: Text("Message"),
                    message: Text(vm.errorState.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loginTextFields() -> some View {
        VStack(spacing: 18) {
            TextField("Enter your email", text: $vm.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .modifier(TextFieldModifier())
            SecureField("Password", text: $vm.password)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
            Button {
                // Forgot password functionality would go here
            } label: {
                Text("Forgot Password?")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundStyle(.blue)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    LoginView()
}
