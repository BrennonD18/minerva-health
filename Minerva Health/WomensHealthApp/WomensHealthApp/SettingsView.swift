//
//  SettingsView.swift
//  WomensHealthApp
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var aiCompanion: AICompanionManager
    @State private var showingCyclePicker = false
    @State private var showingPeriodPicker = false
    @State private var showingPersonalitySettings = false
    @State private var showingBackupConfirmation = false
    @StateObject private var healthKit = HealthKitManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Apple Health
                if healthKit.isHealthDataAvailable {
                    Section {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(AppColors.primary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Health")
                                    .foregroundColor(AppColors.textPrimary)
                                Text(healthKit.isAuthorized ? "Connected" : "Not connected")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            if !healthKit.isAuthorized {
                                Button("Connect") {
                                    Haptics.selection()
                                    Task { await healthKit.requestAuthorization() }
                                }
                                .foregroundColor(AppColors.primary)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.success)
                            }
                        }
                    } header: {
                        Text("Health")
                    } footer: {
                        Text("Your period days, flow, temperature, and sexual activity sync to the Health app when you save a log.")
                    }
                }
                
                // Insights Section
                Section {
                    NavigationLink(destination: StatisticsView()) {
                        SettingsRow(
                            icon: "chart.bar.fill",
                            iconColor: AppColors.accent,
                            title: "Insights"
                        )
                    }
                }
                
                // AI Companion Section
                Section {
                    Button(action: { Haptics.selection(); showingPersonalitySettings = true }) {
                        SettingsRow(
                            icon: "heart.circle.fill",
                            iconColor: AppColors.primary,
                            title: "AI Companion Personality",
                            subtitle: aiCompanion.personality.name
                        )
                    }
                }
                
                // Cycle Settings
                Section {
                    Button(action: { Haptics.selection(); showingCyclePicker = true }) {
                        SettingsRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: AppColors.accent,
                            title: "Duration of cycle",
                            value: "\(dataManager.settings.cycleDuration) days"
                        )
                    }
                    
                    Button(action: { Haptics.selection(); showingPeriodPicker = true }) {
                        SettingsRow(
                            icon: "drop.fill",
                            iconColor: AppColors.periodDay,
                            title: "Duration of period",
                            value: "\(dataManager.settings.periodDuration) days"
                        )
                    }
                    
                    Toggle(isOn: $dataManager.settings.useAverage) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use average")
                                .foregroundColor(AppColors.textPrimary)
                            Text("Calculate durations based on logged data for the last 6 months")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .tint(AppColors.primary)
                    .onChange(of: dataManager.settings.useAverage) { _, _ in
                        Haptics.selection()
                        dataManager.saveData()
                    }
                }
                
                // Temperature Settings
                Section("Temperature") {
                    Picker("Temperature Unit", selection: $dataManager.settings.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .onChange(of: dataManager.settings.temperatureUnit) { _, _ in
                        Haptics.selection()
                        dataManager.saveData()
                    }
                }
                
                // Notifications
                Section("Notifications") {
                    Toggle(isOn: $dataManager.settings.notifyPeriodStart) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(AppColors.periodDay)
                                .frame(width: 28)
                            Text("Notify about the start of the period")
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .tint(AppColors.primary)
                    .onChange(of: dataManager.settings.notifyPeriodStart) { _, _ in
                        Haptics.selection()
                        dataManager.saveData()
                    }
                    
                    Toggle(isOn: $dataManager.settings.notifyOvulation) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(AppColors.ovulation)
                                .frame(width: 28)
                            Text("Notify about the start of ovulation")
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .tint(AppColors.primary)
                    .onChange(of: dataManager.settings.notifyOvulation) { _, _ in
                        Haptics.selection()
                        dataManager.saveData()
                    }
                }
                
                // Backup
                Section {
                    Button(action: { Haptics.selection(); showingBackupConfirmation = true }) {
                        SettingsRow(
                            icon: "arrow.clockwise.icloud.fill",
                            iconColor: AppColors.success,
                            title: "Backup",
                            subtitle: lastBackupString
                        )
                    }
                }
                
                // Theme
                Section("Theme") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            ThemeOption(
                                theme: theme,
                                isSelected: dataManager.settings.selectedTheme == theme,
                                action: {
                                    dataManager.settings.selectedTheme = theme
                                    dataManager.saveData()
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // About
                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: AppColors.textSecondary,
                            title: "About"
                        )
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRow(
                            icon: "lock.shield.fill",
                            iconColor: AppColors.textSecondary,
                            title: "Privacy Policy"
                        )
                    }
                    
                    NavigationLink(destination: TermsView()) {
                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: AppColors.textSecondary,
                            title: "Terms & Conditions"
                        )
                    }
                }
                
                // Support
                Section {
                    Button(action: { Haptics.selection(); shareApp() }) {
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: AppColors.primary,
                            title: "Tell your friends about us"
                        )
                    }
                    
                    Button(action: { Haptics.selection(); contactSupport() }) {
                        SettingsRow(
                            icon: "envelope.fill",
                            iconColor: AppColors.primary,
                            title: "Tech Support"
                        )
                    }
                }
                
                // Version
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onAppear {
                healthKit.refreshAuthorizationStatus()
            }
            .refreshable {
                Haptics.refresh()
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCyclePicker) {
                DurationPickerSheet(
                    title: "Duration of cycle",
                    subtitle: "Choose the number of days",
                    range: 21...40,
                    selection: $dataManager.settings.cycleDuration,
                    onSave: { dataManager.saveData() }
                )
            }
            .sheet(isPresented: $showingPeriodPicker) {
                DurationPickerSheet(
                    title: "Duration of period",
                    subtitle: "Choose the number of days",
                    range: 1...10,
                    selection: $dataManager.settings.periodDuration,
                    onSave: { dataManager.saveData() }
                )
            }
            .sheet(isPresented: $showingPersonalitySettings) {
                PersonalitySettingsView()
            }
            .alert("Backup Data", isPresented: $showingBackupConfirmation) {
                Button("Cancel", role: .cancel) { Haptics.selection() }
                Button("Backup") {
                    Haptics.selection()
                    performBackup()
                }
            } message: {
                Text("Your data will be saved locally. In a future update, cloud backup will be available.")
            }
        }
    }
    
    private var lastBackupString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm:ss a"
        return "Today at \(formatter.string(from: Date()))"
    }
    
    private func performBackup() {
        dataManager.saveData()
        // In production, implement cloud backup here
    }
    
    private func shareApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let text = "Check out this amazing women's health app!"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        window.rootViewController?.present(activityVC, animated: true)
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@example.com") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(AppColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Theme Option

struct ThemeOption: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.backgroundColor)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 3)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.primary)
                            .background(Circle().fill(.white).padding(-2))
                            .offset(x: 25, y: -25)
                    }
                    
                    // Theme preview decoration
                    if theme == .flowers {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(AppColors.success.opacity(0.5))
                            .offset(x: -15, y: 10)
                    }
                }
                
                Text(theme.rawValue)
                    .font(.caption)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

// MARK: - Duration Picker Sheet

struct DurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let subtitle: String
    let range: ClosedRange<Int>
    @Binding var selection: Int
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(subtitle)
                    .foregroundColor(AppColors.textSecondary)
                
                Picker(title, selection: $selection) {
                    ForEach(range, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
                .onChange(of: selection) { _, _ in
                    Haptics.selection()
                }
                
                Button(action: {
                    Haptics.selection()
                    onSave()
                    dismiss()
                }) {
                    Text("Select")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Women's Health Companion")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text("Your personal companion for tracking menstrual health, understanding your cycle, and getting support through an AI-powered health assistant.")
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "calendar", title: "Cycle Tracking", description: "Track your periods and predict future cycles")
                    FeatureRow(icon: "thermometer", title: "Temperature Logging", description: "Monitor basal body temperature")
                    FeatureRow(icon: "heart.fill", title: "AI Companion", description: "Get personalized support and answers")
                    FeatureRow(icon: "chart.bar.fill", title: "Insights", description: "Understand your patterns over time")
                }
                .padding()
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .background(AppColors.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Group {
                    PolicySection(
                        title: "Data Collection",
                        content: "We collect only the health data you choose to log, including cycle information, symptoms, moods, and temperature readings. This data is stored locally on your device."
                    )
                    
                    PolicySection(
                        title: "Data Storage",
                        content: "All your personal health data is stored locally on your device. We do not have access to your personal health information unless you explicitly choose to share it for support purposes."
                    )
                    
                    PolicySection(
                        title: "AI Conversations",
                        content: "Conversations with the AI companion are processed to provide you with helpful responses. These conversations may be used to improve our AI system, but are anonymized and stripped of personally identifiable information."
                    )
                    
                    PolicySection(
                        title: "Third Parties",
                        content: "We do not sell or share your personal health data with third parties for marketing purposes."
                    )
                    
                    PolicySection(
                        title: "Your Rights",
                        content: "You have the right to access, correct, or delete your data at any time. You can export or delete all your data from the app settings."
                    )
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(content)
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Terms View

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms & Conditions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Group {
                    PolicySection(
                        title: "Acceptance of Terms",
                        content: "By using this app, you agree to these terms and conditions. If you do not agree, please do not use the app."
                    )
                    
                    PolicySection(
                        title: "Medical Disclaimer",
                        content: "This app is for informational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition."
                    )
                    
                    PolicySection(
                        title: "AI Companion Disclaimer",
                        content: "The AI companion provides general information and emotional support. It is not a medical professional and cannot diagnose conditions or prescribe treatments. Always consult a healthcare provider for medical concerns."
                    )
                    
                    PolicySection(
                        title: "Accuracy of Predictions",
                        content: "Cycle predictions are estimates based on your logged data. They should not be relied upon for medical decisions or as a sole method of contraception."
                    )
                    
                    PolicySection(
                        title: "User Responsibility",
                        content: "You are responsible for the accuracy of the data you enter and for using the app appropriately. We are not liable for any decisions made based on information provided by the app."
                    )
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle("Terms & Conditions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(DataManager())
        .environmentObject(AICompanionManager())
}
