//
//  DataManager.swift
//  WomensHealthApp
//

import Foundation
import SwiftUI
import Combine

class DataManager: ObservableObject {
    @Published var entries: [CycleEntry] = []
    @Published var cycles: [Cycle] = []
    @Published var settings: UserSettings = UserSettings()
    @Published var chatHistory: [ChatMessage] = []
    
    private let entriesKey = "cycleEntries"
    private let cyclesKey = "cycles"
    private let settingsKey = "userSettings"
    private let chatHistoryKey = "chatHistory"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    
    func loadData() {
        // Load entries
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([CycleEntry].self, from: data) {
            entries = decoded
        }
        
        // Load cycles
        if let data = UserDefaults.standard.data(forKey: cyclesKey),
           let decoded = try? JSONDecoder().decode([Cycle].self, from: data) {
            cycles = decoded
        }
        
        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        }
        
        // Load chat history
        if let data = UserDefaults.standard.data(forKey: chatHistoryKey),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            chatHistory = decoded
        }
    }
    
    // MARK: - HealthKit Sync

    private func syncEntryToHealthKit(_ entry: CycleEntry) {
        let health = HealthKitManager.shared
        guard health.isHealthDataAvailable else { return }

        let date = entry.date

        if entry.isPeriodDay {
            health.writeMenstrualFlow(date: date, flow: entry.flowHeaviness)
        } else {
            health.deleteMenstrualFlow(for: date)
        }

        if let temp = entry.temperature {
            health.writeBasalBodyTemperature(date: date, celsius: temp)
        }

        if let sex = entry.sexActivity, sex != .noSex {
            health.writeSexualActivity(date: date)
        }
    }

    func saveData() {
        // Save entries
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
        
        // Save cycles
        if let encoded = try? JSONEncoder().encode(cycles) {
            UserDefaults.standard.set(encoded, forKey: cyclesKey)
        }
        
        // Save settings
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
        
        // Save chat history
        if let encoded = try? JSONEncoder().encode(chatHistory) {
            UserDefaults.standard.set(encoded, forKey: chatHistoryKey)
        }
    }
    
    // MARK: - Entry Management
    
    func addEntry(_ entry: CycleEntry) {
        let cal = Calendar.current
        let normalizedDate = cal.startOfDay(for: entry.date)
        var newEntry = entry
        newEntry.date = normalizedDate

        entries.removeAll { cal.isDate($0.date, inSameDayAs: normalizedDate) }
        entries.append(newEntry)
        entries.sort { $0.date > $1.date }

        if newEntry.isPeriodDay {
            updateCycles()
        }
        saveData()

        // Sync to Apple Health when authorized
        syncEntryToHealthKit(newEntry)
    }
    
    func getEntry(for date: Date) -> CycleEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func deleteEntry(_ entry: CycleEntry) {
        entries.removeAll { $0.id == entry.id }
        updateCycles()
        saveData()
    }
    
    // MARK: - Period Tracking
    
    func logPeriodDays(_ dates: [Date]) {
        for date in dates {
            if var existingEntry = getEntry(for: date) {
                existingEntry.isPeriodDay = true
                addEntry(existingEntry)
            } else {
                let newEntry = CycleEntry(date: date, isPeriodDay: true)
                addEntry(newEntry)
            }
        }
        updateCycles()
    }
    
    func removePeriodDay(_ date: Date) {
        if var entry = getEntry(for: date) {
            entry.isPeriodDay = false
            HealthKitManager.shared.deleteMenstrualFlow(for: date)
            // If entry has no other data, remove it entirely
            if entry.symptoms.isEmpty && entry.mood == nil && entry.discharge == nil &&
               entry.flowHeaviness == nil && entry.sexActivity == nil && entry.temperature == nil &&
               (entry.notes == nil || entry.notes!.isEmpty) {
                deleteEntry(entry)
            } else {
                addEntry(entry)
            }
        }
        updateCycles()
    }
    
    // MARK: - Cycle Calculations
    
    private func updateCycles() {
        let periodDays = entries.filter { $0.isPeriodDay }.map { $0.date }.sorted()
        
        guard !periodDays.isEmpty else {
            cycles = []
            saveData()
            return
        }
        
        var newCycles: [Cycle] = []
        var currentCycleStart: Date?
        var periodLength = 0
        var lastDate: Date?
        
        for date in periodDays {
            if let last = lastDate {
                let dayDiff = Calendar.current.dateComponents([.day], from: last, to: date).day ?? 0
                
                if dayDiff > 3 { // New period started (gap of more than 3 days)
                    if let start = currentCycleStart {
                        let cycleLength = Calendar.current.dateComponents([.day], from: start, to: date).day
                        let cycle = Cycle(
                            startDate: start,
                            endDate: last,
                            periodLength: periodLength,
                            cycleLength: cycleLength,
                            ovulationDate: calculateOvulationDate(cycleStart: start, cycleLength: cycleLength ?? settings.cycleDuration)
                        )
                        newCycles.append(cycle)
                    }
                    currentCycleStart = date
                    periodLength = 1
                } else {
                    periodLength += 1
                }
            } else {
                currentCycleStart = date
                periodLength = 1
            }
            lastDate = date
        }
        
        // Add current/last cycle
        if let start = currentCycleStart {
            let cycle = Cycle(
                startDate: start,
                endDate: nil, // Current cycle
                periodLength: periodLength
            )
            newCycles.append(cycle)
        }
        
        cycles = newCycles.sorted { $0.startDate > $1.startDate }
        saveData()
    }
    
    func calculateOvulationDate(cycleStart: Date, cycleLength: Int) -> Date {
        // Ovulation typically occurs 14 days before the next period
        let ovulationDay = cycleLength - 14
        return Calendar.current.date(byAdding: .day, value: ovulationDay, to: cycleStart) ?? cycleStart
    }
    
    // MARK: - Statistics
    
    var averageCycleLength: Int {
        let completedCycles = cycles.filter { $0.cycleLength != nil }
        guard !completedCycles.isEmpty else { return settings.cycleDuration }
        let total = completedCycles.compactMap { $0.cycleLength }.reduce(0, +)
        return total / completedCycles.count
    }
    
    var averagePeriodLength: Int {
        guard !cycles.isEmpty else { return settings.periodDuration }
        let total = cycles.map { $0.periodLength }.reduce(0, +)
        return total / cycles.count
    }
    
    var currentCycle: Cycle? {
        cycles.first
    }
    
    var currentCycleDay: Int {
        guard let current = currentCycle else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: current.startDate, to: Date()).day ?? 0
        return days + 1
    }
    
    var daysToOvulation: Int {
        let cycleLength = settings.useAverage ? averageCycleLength : settings.cycleDuration
        let ovulationDay = cycleLength - 14
        let daysRemaining = ovulationDay - currentCycleDay
        return max(0, daysRemaining)
    }
    
    var daysToNextPeriod: Int {
        let cycleLength = settings.useAverage ? averageCycleLength : settings.cycleDuration
        let daysRemaining = cycleLength - currentCycleDay
        return max(0, daysRemaining)
    }
    
    var fertilityStatus: FertilityStatus {
        let ovulationDay = (settings.useAverage ? averageCycleLength : settings.cycleDuration) - 14
        let fertileWindowStart = ovulationDay - 5
        let fertileWindowEnd = ovulationDay + 1
        
        if currentCycleDay >= fertileWindowStart && currentCycleDay <= fertileWindowEnd {
            if currentCycleDay == ovulationDay {
                return .ovulation
            }
            return .fertile
        } else if currentCycleDay <= (settings.useAverage ? averagePeriodLength : settings.periodDuration) {
            return .menstruation
        }
        return .low
    }
    
    var predictedPeriodDates: [Date] {
        guard let current = currentCycle else { return [] }
        let cycleLength = settings.useAverage ? averageCycleLength : settings.cycleDuration
        let periodLength = settings.useAverage ? averagePeriodLength : settings.periodDuration
        
        var dates: [Date] = []
        if let nextPeriodStart = Calendar.current.date(byAdding: .day, value: cycleLength, to: current.startDate) {
            for i in 0..<periodLength {
                if let date = Calendar.current.date(byAdding: .day, value: i, to: nextPeriodStart) {
                    dates.append(date)
                }
            }
        }
        return dates
    }
    
    var predictedOvulationDate: Date? {
        guard let current = currentCycle else { return nil }
        let cycleLength = settings.useAverage ? averageCycleLength : settings.cycleDuration
        return calculateOvulationDate(cycleStart: current.startDate, cycleLength: cycleLength)
    }
    
    var predictedFertileWindow: [Date] {
        guard let ovulation = predictedOvulationDate else { return [] }
        var dates: [Date] = []
        for i in -5...1 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: ovulation) {
                dates.append(date)
            }
        }
        return dates
    }
    
    // MARK: - Chat History
    
    func addChatMessage(_ message: ChatMessage) {
        chatHistory.append(message)
        saveData()
    }
    
    func clearChatHistory() {
        chatHistory.removeAll()
        saveData()
    }
    
    // MARK: - Temperature Data
    
    var temperatureData: [(Date, Double)] {
        entries
            .filter { $0.temperature != nil }
            .map { ($0.date, $0.temperature!) }
            .sorted { $0.0 < $1.0 }
    }
}

// MARK: - Fertility Status
enum FertilityStatus {
    case low
    case fertile
    case ovulation
    case menstruation
    
    var description: String {
        switch self {
        case .low: return "Low"
        case .fertile: return "Fertile"
        case .ovulation: return "Ovulation"
        case .menstruation: return "Period"
        }
    }
    
    var pregnancyChance: String {
        switch self {
        case .low: return "Low chance of getting pregnant"
        case .fertile: return "High chance of getting pregnant"
        case .ovulation: return "Peak fertility"
        case .menstruation: return "Very low chance of getting pregnant"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return AppColors.textSecondary
        case .fertile: return AppColors.fertileDay
        case .ovulation: return AppColors.ovulation
        case .menstruation: return AppColors.periodDay
        }
    }
}
