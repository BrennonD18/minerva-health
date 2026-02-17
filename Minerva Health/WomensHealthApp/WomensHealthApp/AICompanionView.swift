//
//  AICompanionView.swift
//  WomensHealthApp
//

import SwiftUI

struct AICompanionView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var aiCompanion: AICompanionManager
    @State private var messageText = ""
    @State private var showingPersonalitySettings = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message if no history
                            if aiCompanion.conversationHistory.isEmpty {
                                welcomeView
                            }
                            
                            // Chat messages
                            ForEach(aiCompanion.conversationHistory) { message in
                                MessageBubble(message: message, aiName: aiCompanion.personality.name)
                                    .id(message.id)
                            }
                            
                            // Loading indicator
                            if aiCompanion.isLoading {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        Haptics.refresh()
                        try? await Task.sleep(nanoseconds: 300_000_000)
                    }
                    .onChange(of: aiCompanion.conversationHistory.count) { _, _ in
                        withAnimation {
                            if let lastMessage = aiCompanion.conversationHistory.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: aiCompanion.isLoading) { _, isLoading in
                        if isLoading {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Quick Prompts
                if aiCompanion.conversationHistory.isEmpty {
                    quickPrompts
                }
                
                // Input Area
                inputArea
            }
            .background(AppColors.background)
            .navigationTitle(aiCompanion.personality.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { Haptics.selection(); showingPersonalitySettings = true }) {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppColors.accent)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { Haptics.selection(); aiCompanion.clearHistory() }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                        
                        Button(action: { Haptics.selection(); showingPersonalitySettings = true }) {
                            Label("Customize Personality", systemImage: "person.fill.questionmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingPersonalitySettings) {
                PersonalitySettingsView()
            }
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            // Avatar
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
                Text("Hi, I'm \(aiCompanion.personality.name)! 👋")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Your personal health companion")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text("I'm here to support you with questions about your cycle, symptoms, emotions, and overall wellbeing. Ask me anything – I'm a safe space to talk about women's health. 💕")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Cycle context card
            cycleContextCard
        }
        .padding(.vertical, 30)
    }
    
    // MARK: - Cycle Context Card
    
    private var cycleContextCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Current Cycle")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Day \(dataManager.currentCycleDay) • \(dataManager.fertilityStatus.description)")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "calendar.circle.fill")
                    .font(.title)
                    .foregroundColor(AppColors.primary)
            }
            
            HStack(spacing: 16) {
                StatPill(
                    title: "Ovulation in",
                    value: "\(dataManager.daysToOvulation) days",
                    color: AppColors.ovulation
                )
                
                StatPill(
                    title: "Period in",
                    value: "\(dataManager.daysToNextPeriod) days",
                    color: AppColors.periodDay
                )
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Prompts
    
    private var quickPrompts: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickPromptButton(text: "Why do I feel so tired?") {
                    sendMessage("Why do I feel so tired before my period?")
                }
                
                QuickPromptButton(text: "Help with cramps") {
                    sendMessage("What can help with menstrual cramps?")
                }
                
                QuickPromptButton(text: "Mood swings") {
                    sendMessage("I'm having really bad mood swings lately")
                }
                
                QuickPromptButton(text: "What does my discharge mean?") {
                    sendMessage("Can you explain what different types of discharge mean?")
                }
                
                QuickPromptButton(text: "Self-care tips") {
                    sendMessage("What self-care should I focus on during my period?")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text Field
                HStack {
                    TextField("Message \(aiCompanion.personality.name)...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                    
                    if !messageText.isEmpty {
                        Button(action: { Haptics.selection(); messageText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                // Send Button
                Button(action: { Haptics.selection(); sendMessage(messageText) }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(messageText.isEmpty ? AppColors.textSecondary : AppColors.primary)
                }
                .disabled(messageText.isEmpty || aiCompanion.isLoading)
            }
            .padding()
            .background(AppColors.cardBackground)
        }
    }
    
    // MARK: - Send Message
    
    private func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        
        let message = text
        messageText = ""
        isInputFocused = false
        
        // Build cycle context
        let context = CycleContext(
            currentDay: dataManager.currentCycleDay,
            daysToOvulation: dataManager.daysToOvulation,
            daysToNextPeriod: dataManager.daysToNextPeriod,
            phase: dataManager.fertilityStatus.description,
            recentSymptoms: getRecentSymptoms(),
            recentMood: getRecentMood()
        )
        
        Task {
            await aiCompanion.sendMessage(message, cycleContext: context)
        }
    }
    
    private func getRecentSymptoms() -> [String] {
        let recentEntries = dataManager.entries.prefix(3)
        return Array(Set(recentEntries.flatMap { $0.symptoms.map { $0.rawValue } }))
    }
    
    private func getRecentMood() -> String? {
        dataManager.entries.first?.mood?.rawValue
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let aiName: String
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 12) {
                if !message.isFromUser {
                    // AI Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(message.isFromUser ? .white : AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            message.isFromUser ?
                            AnyShapeStyle(LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )) :
                            AnyShapeStyle(AppColors.cardBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: geometry.size.width * 0.75, alignment: message.isFromUser ? .trailing : .leading)
                
                if message.isFromUser {
                    Spacer(minLength: 36)
                }
            }
            .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppColors.textSecondary)
                        .frame(width: 8, height: 8)
                        .offset(y: animating ? -5 : 5)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Quick Prompt Button

struct QuickPromptButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Personality Settings View

struct PersonalitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var aiCompanion: AICompanionManager
    @State private var name: String = ""
    @State private var selectedTone: PersonalityTone = .warm
    @State private var selectedStyle: CommunicationStyle = .supportive
    @State private var selectedSupport: SupportLevel = .balanced
    @State private var customDescription: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        // Avatar preview
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        Text("Customize Your AI Companion")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Make \(name.isEmpty ? "your companion" : name) feel like the perfect support for you")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .listRowBackground(Color.clear)
                }
                
                Section("Name") {
                    TextField("Companion name", text: $name)
                }
                
                Section("Personality Tone") {
                    ForEach(PersonalityTone.allCases, id: \.self) { tone in
                        Button(action: { Haptics.selection(); selectedTone = tone }) {
                            HStack {
                                Text(tone.emoji)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tone.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text(tone.description)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if selectedTone == tone {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                    }
                }
                
                Section("Communication Style") {
                    ForEach(CommunicationStyle.allCases, id: \.self) { style in
                        Button(action: { Haptics.selection(); selectedStyle = style }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text(style.description)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if selectedStyle == style {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                    }
                }
                
                Section("Support Level") {
                    Picker("Support Level", selection: $selectedSupport) {
                        ForEach(SupportLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedSupport) { _, _ in
                        Haptics.selection()
                    }
                    
                    Text(selectedSupport.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Section("Custom Personality Description (Optional)") {
                    TextEditor(text: $customDescription)
                        .frame(minHeight: 100)
                    
                    Text("Describe any additional personality traits you'd like. For example: \"Be encouraging about fitness goals\" or \"Use gentle humor when appropriate\"")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationTitle("Companion Personality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        Haptics.selection()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Haptics.selection()
                        savePersonality()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentPersonality()
            }
        }
    }
    
    private func loadCurrentPersonality() {
        name = aiCompanion.personality.name
        selectedTone = aiCompanion.personality.tone
        selectedStyle = aiCompanion.personality.communicationStyle
        selectedSupport = aiCompanion.personality.supportLevel
        customDescription = aiCompanion.personality.customDescription ?? ""
    }
    
    private func savePersonality() {
        aiCompanion.personality = AIPersonality(
            name: name.isEmpty ? "Luna" : name,
            tone: selectedTone,
            communicationStyle: selectedStyle,
            supportLevel: selectedSupport,
            customDescription: customDescription.isEmpty ? nil : customDescription
        )
        aiCompanion.savePersonality()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AICompanionView()
        .environmentObject(DataManager())
        .environmentObject(AICompanionManager())
}
