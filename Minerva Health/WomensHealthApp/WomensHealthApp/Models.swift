//
//  Models.swift
//  WomensHealthApp
//

import Foundation
import SwiftUI

// MARK: - Cycle Entry
struct CycleEntry: Identifiable, Codable {
    let id: UUID
    var date: Date
    var isPeriodDay: Bool
    var symptoms: [Symptom]
    var mood: Mood?
    var discharge: DischargeType?
    var dischargeColor: DischargeColor?
    var flowHeaviness: FlowHeaviness?
    var sexActivity: SexActivity?
    var temperature: Double? // Basal body temperature in Celsius
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        isPeriodDay: Bool = false,
        symptoms: [Symptom] = [],
        mood: Mood? = nil,
        discharge: DischargeType? = nil,
        dischargeColor: DischargeColor? = nil,
        flowHeaviness: FlowHeaviness? = nil,
        sexActivity: SexActivity? = nil,
        temperature: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.isPeriodDay = isPeriodDay
        self.symptoms = symptoms
        self.mood = mood
        self.discharge = discharge
        self.dischargeColor = dischargeColor
        self.flowHeaviness = flowHeaviness
        self.sexActivity = sexActivity
        self.temperature = temperature
        self.notes = notes
    }
}

// MARK: - Mood
enum Mood: String, Codable, CaseIterable {
    case cheerful = "Cheerful"
    case calm = "Calm"
    case energetic = "Energetic"
    case playful = "Playful"
    case moodSwings = "Mood swings"
    case sad = "Sad"
    case indifferent = "Indifferent"
    case angry = "Angry"
    case anxious = "Anxious"
    case confused = "Confused"
    case depressed = "Depressed"
    case irritable = "Irritable"
    case sensitive = "Sensitive"
    case hopeful = "Hopeful"
    case content = "Content"
    
    var emoji: String {
        switch self {
        case .cheerful: return "😊"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .playful: return "🎉"
        case .moodSwings: return "🎭"
        case .sad: return "😢"
        case .indifferent: return "😐"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .confused: return "😕"
        case .depressed: return "😔"
        case .irritable: return "😤"
        case .sensitive: return "🥺"
        case .hopeful: return "🌟"
        case .content: return "☺️"
        }
    }
    
    var color: Color {
        switch self {
        case .cheerful, .energetic, .playful, .hopeful:
            return Color(red: 1.0, green: 0.8, blue: 0.4) // Warm yellow
        case .calm, .content:
            return Color(red: 0.6, green: 0.85, blue: 0.75) // Soft teal
        case .sad, .depressed:
            return Color(red: 0.6, green: 0.7, blue: 0.85) // Soft blue
        case .moodSwings, .confused:
            return Color(red: 0.85, green: 0.75, blue: 0.90) // Light purple
        case .angry, .irritable:
            return Color(red: 0.95, green: 0.6, blue: 0.6) // Soft red
        case .anxious, .sensitive:
            return Color(red: 0.9, green: 0.75, blue: 0.85) // Soft pink
        case .indifferent:
            return Color(red: 0.8, green: 0.8, blue: 0.8) // Gray
        }
    }
}

// MARK: - Symptoms
enum Symptom: String, Codable, CaseIterable {
    case everythingsFine = "Everything's fine"
    case abdominalCramps = "Abdominal cramps"
    case headache = "Headache"
    case fatigue = "Fatigue"
    case acne = "Acne (pimples)"
    case tenderBreasts = "Tender breasts"
    case bloating = "Bloating"
    case nausea = "Nausea"
    case constipation = "Constipation"
    case diarrhea = "Diarrhea"
    case backPain = "Back pain"
    case legPain = "Leg pain"
    case insomnia = "Insomnia"
    case cravings = "Cravings"
    case hotFlashes = "Hot flashes"
    case dizziness = "Dizziness"
    case chills = "Chills"
    case jointPain = "Joint pain"
    
    var icon: String {
        switch self {
        case .everythingsFine: return "checkmark.circle.fill"
        case .abdominalCramps: return "bandage.fill"
        case .headache: return "brain.head.profile"
        case .fatigue: return "battery.25"
        case .acne: return "face.smiling"
        case .tenderBreasts: return "heart.fill"
        case .bloating: return "wind"
        case .nausea: return "tornado"
        case .constipation, .diarrhea: return "pills.fill"
        case .backPain: return "figure.walk"
        case .legPain: return "figure.stand"
        case .insomnia: return "moon.zzz.fill"
        case .cravings: return "fork.knife"
        case .hotFlashes: return "thermometer.sun.fill"
        case .dizziness: return "arrow.triangle.2.circlepath"
        case .chills: return "snowflake"
        case .jointPain: return "figure.flexibility"
        }
    }
}

// MARK: - Discharge Type
enum DischargeType: String, Codable, CaseIterable {
    case none = "No discharge"
    case spotting = "Spotting"
    case sticky = "Sticky"
    case creamy = "Creamy"
    case mucousy = "Mucousy"
    case watery = "Watery"
    case eggWhite = "Egg white"
    case abnormal = "Abnormal"
    
    var description: String {
        switch self {
        case .none: return "No noticeable discharge"
        case .spotting: return "Light blood or brown spots"
        case .sticky: return "Thick and sticky texture"
        case .creamy: return "White or off-white, lotion-like"
        case .mucousy: return "Thick and mucus-like"
        case .watery: return "Clear and thin"
        case .eggWhite: return "Clear, stretchy (fertile sign)"
        case .abnormal: return "Unusual - select color below"
        }
    }
}

// MARK: - Discharge Color (for abnormal discharge)
enum DischargeColor: String, Codable, CaseIterable {
    case clear = "Clear"
    case white = "White"
    case offWhite = "Off-white/Cream"
    case yellow = "Yellow"
    case yellowGreen = "Yellow-green"
    case green = "Green"
    case gray = "Gray"
    case pink = "Pink"
    case brown = "Brown"
    case red = "Red/Bloody"
    
    var color: Color {
        switch self {
        case .clear: return Color(white: 0.95)
        case .white: return .white
        case .offWhite: return Color(red: 1.0, green: 0.98, blue: 0.90)
        case .yellow: return Color(red: 1.0, green: 0.95, blue: 0.60)
        case .yellowGreen: return Color(red: 0.85, green: 0.95, blue: 0.50)
        case .green: return Color(red: 0.60, green: 0.90, blue: 0.60)
        case .gray: return Color(white: 0.75)
        case .pink: return Color(red: 1.0, green: 0.80, blue: 0.85)
        case .brown: return Color(red: 0.60, green: 0.45, blue: 0.35)
        case .red: return Color(red: 0.90, green: 0.40, blue: 0.40)
        }
    }
    
    var healthNote: String {
        switch self {
        case .clear, .white, .offWhite:
            return "Typically normal and healthy"
        case .yellow:
            return "May be normal or indicate mild infection"
        case .yellowGreen, .green:
            return "Could indicate bacterial infection - consider consulting a doctor"
        case .gray:
            return "May indicate bacterial vaginosis - consider consulting a doctor"
        case .pink:
            return "May be normal spotting or light bleeding"
        case .brown:
            return "Often old blood - can be normal, especially before/after period"
        case .red:
            return "Fresh blood - normal during period, otherwise consult a doctor"
        }
    }
}

// MARK: - Flow Heaviness
enum FlowHeaviness: String, Codable, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"
    
    var icon: String {
        switch self {
        case .light: return "drop"
        case .medium: return "drop.fill"
        case .heavy: return "drop.degreesign.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .light: return Color(red: 0.95, green: 0.70, blue: 0.75)
        case .medium: return Color(red: 0.93, green: 0.47, blue: 0.57)
        case .heavy: return Color(red: 0.80, green: 0.30, blue: 0.40)
        }
    }
}

// MARK: - Sex Activity
enum SexActivity: String, Codable, CaseIterable {
    case protectedSex = "Protected sex"
    case unprotectedSex = "Unprotected sex"
    case noSex = "No sex"
    case strongDesire = "Strong desire"
    case masturbation = "Masturbation"
    case lowDesire = "Low desire"
    
    var icon: String {
        switch self {
        case .protectedSex: return "shield.checkered"
        case .unprotectedSex: return "heart.fill"
        case .noSex: return "minus.circle"
        case .strongDesire: return "flame.fill"
        case .masturbation: return "sparkles"
        case .lowDesire: return "heart.slash"
        }
    }
}

// MARK: - Cycle Statistics
struct CycleStatistics: Codable {
    var averageCycleLength: Int
    var averagePeriodLength: Int
    var cycles: [Cycle]
    
    init(averageCycleLength: Int = 28, averagePeriodLength: Int = 5, cycles: [Cycle] = []) {
        self.averageCycleLength = averageCycleLength
        self.averagePeriodLength = averagePeriodLength
        self.cycles = cycles
    }
}

// MARK: - Individual Cycle
struct Cycle: Identifiable, Codable {
    let id: UUID
    var startDate: Date
    var endDate: Date?
    var periodLength: Int
    var cycleLength: Int?
    var ovulationDate: Date?
    
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        periodLength: Int = 5,
        cycleLength: Int? = nil,
        ovulationDate: Date? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.periodLength = periodLength
        self.cycleLength = cycleLength
        self.ovulationDate = ovulationDate
    }
}

// MARK: - AI Companion Personality
struct AIPersonality: Codable, Identifiable {
    let id: UUID
    var name: String
    var tone: PersonalityTone
    var communicationStyle: CommunicationStyle
    var supportLevel: SupportLevel
    var customDescription: String?
    
    init(
        id: UUID = UUID(),
        name: String = "Luna",
        tone: PersonalityTone = .warm,
        communicationStyle: CommunicationStyle = .supportive,
        supportLevel: SupportLevel = .balanced,
        customDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.tone = tone
        self.communicationStyle = communicationStyle
        self.supportLevel = supportLevel
        self.customDescription = customDescription
    }
    
    var systemPrompt: String {
        var prompt = """
        You are \(name), a compassionate and knowledgeable AI health companion specializing in women's health.
        
        Your personality traits:
        - Tone: \(tone.description)
        - Communication Style: \(communicationStyle.description)
        - Support Level: \(supportLevel.description)
        
        """
        
        if let custom = customDescription, !custom.isEmpty {
            prompt += """
            Additional personality traits requested by the user:
            \(custom)
            
            """
        }
        
        prompt += """
        Guidelines:
        1. Always be empathetic, understanding, and non-judgmental
        2. Provide accurate, science-based information about women's health
        3. Never diagnose conditions - encourage consulting healthcare providers for medical concerns
        4. Be sensitive to the emotional aspects of menstrual health, fertility, and reproductive topics
        5. Use inclusive language and acknowledge that experiences vary
        6. Remember this is a personal health conversation - maintain privacy and trust
        7. Offer practical tips and emotional support as appropriate
        8. Validate feelings and experiences
        9. When discussing symptoms, explain possible causes but always recommend professional consultation for persistent or concerning issues
        10. Be encouraging about self-care and body awareness
        """
        
        return prompt
    }
}

enum PersonalityTone: String, Codable, CaseIterable {
    case warm = "Warm & Nurturing"
    case professional = "Professional & Informative"
    case playful = "Playful & Uplifting"
    case gentle = "Gentle & Calming"
    case direct = "Direct & Practical"
    case encouraging = "Encouraging & Motivating"
    
    var description: String {
        switch self {
        case .warm: return "Warm, nurturing, and motherly - like talking to a caring friend"
        case .professional: return "Professional and informative - focused on facts and clarity"
        case .playful: return "Playful and uplifting - bringing lightness to difficult topics"
        case .gentle: return "Gentle and calming - soothing and reassuring presence"
        case .direct: return "Direct and practical - no-nonsense, efficient communication"
        case .encouraging: return "Encouraging and motivating - positive and empowering"
        }
    }
    
    var emoji: String {
        switch self {
        case .warm: return "🤗"
        case .professional: return "👩‍⚕️"
        case .playful: return "✨"
        case .gentle: return "🌸"
        case .direct: return "💪"
        case .encouraging: return "🌟"
        }
    }
}

enum CommunicationStyle: String, Codable, CaseIterable {
    case supportive = "Supportive Listener"
    case educational = "Educational Expert"
    case conversational = "Conversational Friend"
    case concise = "Concise & Clear"
    case detailed = "Detailed & Thorough"
    
    var description: String {
        switch self {
        case .supportive: return "Focuses on emotional support and validation"
        case .educational: return "Provides detailed explanations and health information"
        case .conversational: return "Casual, friendly chat style"
        case .concise: return "Brief, to-the-point responses"
        case .detailed: return "Comprehensive, thorough explanations"
        }
    }
}

enum SupportLevel: String, Codable, CaseIterable {
    case high = "High Support"
    case balanced = "Balanced"
    case informational = "Information-Focused"
    
    var description: String {
        switch self {
        case .high: return "Maximum emotional support and encouragement"
        case .balanced: return "Mix of emotional support and practical information"
        case .informational: return "Primarily factual information with light support"
        }
    }
}

// MARK: - Chat Message
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

// MARK: - User Settings
struct UserSettings: Codable {
    var cycleDuration: Int
    var periodDuration: Int
    var useAverage: Bool
    var notifyPeriodStart: Bool
    var notifyOvulation: Bool
    var selectedTheme: AppTheme
    var aiPersonality: AIPersonality
    var temperatureUnit: TemperatureUnit
    
    init(
        cycleDuration: Int = 28,
        periodDuration: Int = 5,
        useAverage: Bool = false,
        notifyPeriodStart: Bool = true,
        notifyOvulation: Bool = true,
        selectedTheme: AppTheme = .white,
        aiPersonality: AIPersonality = AIPersonality(),
        temperatureUnit: TemperatureUnit = .celsius
    ) {
        self.cycleDuration = cycleDuration
        self.periodDuration = periodDuration
        self.useAverage = useAverage
        self.notifyPeriodStart = notifyPeriodStart
        self.notifyOvulation = notifyOvulation
        self.selectedTheme = selectedTheme
        self.aiPersonality = aiPersonality
        self.temperatureUnit = temperatureUnit
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case white = "White"
    case blue = "Blue"
    case flowers = "Flowers"
    case softPink = "Soft Pink"
    case aesthetic = "Aesthetic"
    
    var backgroundColor: Color {
        switch self {
        case .white: return Color(red: 0.99, green: 0.97, blue: 0.98)
        case .blue: return Color(red: 0.90, green: 0.95, blue: 1.0)
        case .flowers: return Color(red: 0.98, green: 0.96, blue: 0.98)
        case .softPink: return Color(red: 1.0, green: 0.95, blue: 0.96)
        case .aesthetic: return Color(red: 0.96, green: 0.94, blue: 0.92)
        }
    }
}

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "Celsius (°C)"
    case fahrenheit = "Fahrenheit (°F)"
    
    func convert(_ value: Double, from: TemperatureUnit) -> Double {
        if self == from { return value }
        switch self {
        case .celsius:
            return (value - 32) * 5/9
        case .fahrenheit:
            return value * 9/5 + 32
        }
    }
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}
