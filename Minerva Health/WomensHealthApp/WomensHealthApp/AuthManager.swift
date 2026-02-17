//
//  AuthManager.swift
//  WomensHealthApp
//

import Foundation
import Security
import Combine

/// Auth state and API token. Persists token in Keychain; shows login screen when not authenticated.
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    /// Base URL for the Minerva backend. Replace with your Railway backend URL (no trailing slash).
    static var apiBaseURL: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MINERVA_API_URL"] ?? "minerva-health-production.up.railway.app"
        #else
        return "minerva-health-production.up.railway.app"
        #endif
    }

    @Published private(set) var isLoggedIn = false
    @Published private(set) var currentUser: AuthUser?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let tokenKey = "com.minervahealth.authToken"
    private let userKey = "com.minervahealth.authUser"

    private init() {
        loadPersistedAuth()
    }

    var authToken: String? {
        get { loadTokenFromKeychain() }
        set {
            if let newValue = newValue {
                saveTokenToKeychain(newValue)
            } else {
                deleteTokenFromKeychain()
            }
        }
    }

    // MARK: - Persistence

    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func saveTokenToKeychain(_ token: String) {
        deleteTokenFromKeychain()
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func loadPersistedAuth() {
        let token = loadTokenFromKeychain()
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            currentUser = user
            isLoggedIn = (token != nil)
        } else {
            currentUser = nil
            isLoggedIn = false
        }
    }

    private func persistUser(_ user: AuthUser?) {
        currentUser = user
        if let user = user, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userKey)
        }
    }

    // MARK: - API

    /// Call after Sign in with Apple returns identity token and user identifier.
    func loginWithApple(appleId: String, identityToken: String?, email: String?, name: String?) async {
        await performLogin(endpoint: "/auth/apple", body: [
            "appleId": appleId,
            "email": email as Any,
            "name": name as Any,
        ])
    }

    /// Call after Google Sign-In returns user ID (sub) and optional email/name.
    func loginWithGoogle(googleId: String, email: String?, name: String?) async {
        await performLogin(endpoint: "/auth/google", body: [
            "googleId": googleId,
            "email": email as Any,
            "name": name as Any,
        ])
    }

    /// Sign in with email and password.
    func loginWithEmail(email: String, password: String) async {
        await performLogin(endpoint: "/auth/login", body: [
            "email": email,
            "password": password,
        ])
    }

    /// Create account with email and password.
    func registerWithEmail(email: String, password: String, name: String?) async {
        var body: [String: Any] = ["email": email, "password": password]
        if let name = name, !name.isEmpty { body["name"] = name }
        await performLogin(endpoint: "/auth/register", body: body)
    }

    private func performLogin(endpoint: String, body: [String: Any]) async {
        guard let url = URL(string: Self.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + endpoint) else {
            await MainActor.run { errorMessage = "Invalid server URL" }
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { @MainActor in isLoading = false } }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            guard http.statusCode == 200 || http.statusCode == 201 else {
                let msg = (try? JSONDecoder().decode(APIError.self, from: data))?.error ?? "Login failed"
                await MainActor.run { errorMessage = msg }
                return
            }
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            await MainActor.run {
                authToken = authResponse.token
                persistUser(authResponse.user)
                isLoggedIn = true
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    func logout() {
        authToken = nil
        persistUser(nil)
        isLoggedIn = false
        errorMessage = nil
    }
}

// MARK: - Models

struct AuthUser: Codable {
    let id: String
    let appleId: String?
    let googleId: String?
    let email: String?
    let name: String?
    let createdAt: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: AuthUser
}

struct APIError: Codable {
    let error: String
}
