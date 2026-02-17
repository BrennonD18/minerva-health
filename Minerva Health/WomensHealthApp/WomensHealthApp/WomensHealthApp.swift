//
//  WomensHealthApp.swift
//  WomensHealthApp
//
//  A comprehensive women's health tracking app with AI companion
//

import SwiftUI

@main
struct WomensHealthApp: App {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var dataManager = DataManager()
    @StateObject private var aiCompanion = AICompanionManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoggedIn {
                    ContentView()
                        .environmentObject(dataManager)
                        .environmentObject(aiCompanion)
                } else {
                    LoginView()
                }
            }
            .onAppear {
                HealthKitManager.shared.refreshAuthorizationStatus()
            }
        }
    }
}
