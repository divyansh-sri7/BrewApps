//
//  AuthView.swift
//  GlassCast - Matches Auth.png design exactly
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    init(authManager: AuthenticationManager) {
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(authManager: authManager))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.4, green: 0.42, blue: 0.85), Color(red: 0.5, green: 0.52, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "cloud.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)

                Text("GlassCast")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)


                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        TextField("", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        SecureField("", text: $viewModel.password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    if viewModel.mode == .login {
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {}
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(viewModel.mode == .login ? "Sign In" : "Sign Up")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 32)

                Text("OR CONTINUE WITH")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)

                HStack(spacing: 16) {
                    Button {} label: {
                        Image(systemName: "applelogo")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }

                    Button {} label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }

                Button {
                    viewModel.toggleMode()
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.mode == .login ? "Don't have an account?" : "Already have an account?")
                            .foregroundStyle(.white.opacity(0.9))
                        Text(viewModel.mode == .login ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .font(.system(size: 14))
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .toast(message: $viewModel.errorMessage)
    }
}
