//
//  ContentView.swift
//  WomensHealthApp
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var aiCompanion: AICompanionManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Daily Log — main screen
            LogView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Log")
                }
                .tag(0)
            
            HomeView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(1)
            
            AICompanionView()
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Luna")
                }
                .tag(2)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Insights")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(AppColors.primary)
        .onChange(of: selectedTab) { _, _ in
            Haptics.selection()
        }
    }
}

// MARK: - App Colors
struct AppColors {
    static let primary = Color(red: 0.93, green: 0.47, blue: 0.57) // Soft coral pink
    static let secondary = Color(red: 0.98, green: 0.91, blue: 0.93) // Light blush
    static let accent = Color(red: 0.71, green: 0.45, blue: 0.60) // Dusty mauve
    static let background = Color(red: 0.99, green: 0.97, blue: 0.98) // Almost white with pink tint
    static let textPrimary = Color(red: 0.33, green: 0.22, blue: 0.27) // Dark mauve
    static let textSecondary = Color(red: 0.55, green: 0.45, blue: 0.50) // Medium mauve
    static let fertileDay = Color(red: 0.85, green: 0.75, blue: 0.90) // Light purple
    static let ovulation = Color(red: 0.60, green: 0.40, blue: 0.70) // Purple
    static let periodDay = Color(red: 0.93, green: 0.47, blue: 0.57) // Coral pink
    static let cardBackground = Color.white
    static let success = Color(red: 0.40, green: 0.78, blue: 0.55) // Soft green
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(DataManager())
        .environmentObject(AICompanionManager())
}
