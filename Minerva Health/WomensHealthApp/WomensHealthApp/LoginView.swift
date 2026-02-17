//
//  LoginView.swift
//  WomensHealthApp
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import UIKit

struct LoginView: View {
    @StateObject private var auth = AuthManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(white: 0.12) : AppColors.background)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Logo / title
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(AppColors.primary)
                        Text("Minerva Health")
                            .font(.title.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Your cycle & wellness companion")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.top, 40)

                    // Email / password form
                    VStack(spacing: 14) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .textFieldStyle(.roundedBorder)
                        if isSignUp {
                            TextField("Name (optional)", text: $name)
                                .textContentType(.name)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button(action: submitEmailAuth) {
                            Text(isSignUp ? "Create account" : "Sign in with email")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(AppColors.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)

                        Button(action: { Haptics.selection(); isSignUp.toggle() }) {
                            Text(isSignUp ? "Already have an account? Sign in" : "Create an account")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)

                    Text("or continue with")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.top, 8)

                    VStack(spacing: 16) {
                        SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                        SignInWithGoogleButton(action: signInWithGoogle)
                            .frame(height: 50)
                    }
                    .padding(.horizontal, 28)

                    if auth.isLoading {
                        ProgressView()
                            .padding(.top, 8)
                    }
                    if let message = auth.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func submitEmailAuth() {
        Haptics.selection()
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return }
        if isSignUp {
            guard password.count >= 8 else {
                auth.errorMessage = "Password must be at least 8 characters"
                return
            }
            Task { await auth.registerWithEmail(email: trimmedEmail, password: password, name: name.isEmpty ? nil : name) }
        } else {
            Task { await auth.loginWithEmail(email: trimmedEmail, password: password) }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            let appleId = appleIDCredential.user
            let identityToken = appleIDCredential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            let email = appleIDCredential.email
            var name: String?
            if let fullName = appleIDCredential.fullName {
                let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
                if !components.isEmpty { name = components.joined(separator: " ") }
            }
            Task {
                await auth.loginWithApple(appleId: appleId, identityToken: identityToken, email: email, name: name)
            }
        case .failure(let error):
            Task { @MainActor in
                auth.errorMessage = error.localizedDescription
            }
        }
    }

    private func signInWithGoogle() {
        Task {
            await GoogleSignInHelper.signIn(auth: auth)
        }
    }
}

// MARK: - Sign in with Google button (custom style to match Apple button)

struct SignInWithGoogleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.title2)
                Text("Sign in with Google")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .foregroundStyle(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Google Sign-In helper

enum GoogleSignInHelper {
    static func signIn(auth: AuthManager) async {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String, !clientID.isEmpty else {
            await MainActor.run {
                auth.errorMessage = "Google Sign-In: Add your iOS client ID to Info.plist as GIDClientID (from Google Cloud Console)."
            }
            return
        }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            await MainActor.run { auth.errorMessage = "Could not present Google Sign-In." }
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let userID = result.user.userID else {
                await MainActor.run { auth.errorMessage = "No user ID from Google." }
                return
            }
            let email = result.user.profile?.email
            let name = result.user.profile?.name
            await auth.loginWithGoogle(googleId: userID, email: email, name: name)
        } catch {
            await MainActor.run { auth.errorMessage = error.localizedDescription }
        }
    }
}

#Preview {
    LoginView()
}
