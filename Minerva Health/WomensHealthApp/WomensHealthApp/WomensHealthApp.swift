//
//  WomensHealthApp.swift
//  WomensHealthApp
//
//  A comprehensive women's health tracking app with AI companion
//

import SwiftUI

@main
struct WomensHealthApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var aiCompanion = AICompanionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(aiCompanion)
                .onAppear {
                    HealthKitManager.shared.refreshAuthorizationStatus()
                }
        }
    }
}
