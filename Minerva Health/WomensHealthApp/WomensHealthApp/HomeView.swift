//
//  HomeView.swift
//  WomensHealthApp
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showingPeriodSelector = false
    @State private var displayedMonth = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Header
                    statusHeader
                    
                    // Calendar
                    calendarView
                    
                    // Quick Actions
                    quickActions
                    
                    // Today's Summary
                    if let todayEntry = dataManager.getEntry(for: Date()) {
                        todaySummary(entry: todayEntry)
                    }
                }
                .padding()
            }
            .refreshable {
                Haptics.refresh()
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            .background(AppColors.background)
            .navigationTitle(formattedDate(Date()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { Haptics.selection(); showingPeriodSelector = true }) {
                            Label("Log Period Days", systemImage: "drop.fill")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingPeriodSelector) {
                PeriodSelectorView()
            }
        }
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        HStack(spacing: 0) {
            // Days to Ovulation
            VStack(spacing: 4) {
                Text("\(dataManager.daysToOvulation)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("days to ovulation")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
            
            // Fertility Status
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                    Text(dataManager.fertilityStatus.description)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(dataManager.fertilityStatus.color)
                
                Text("chance of")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text("getting pregnant")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
            
            // Day of Cycle
            VStack(spacing: 4) {
                Text("\(dataManager.currentCycleDay)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("day of cycle")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppColors.secondary, AppColors.secondary.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Calendar View
    
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button(action: { Haptics.selection(); previousMonth() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Text(monthYearString(displayedMonth))
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: { Haptics.selection(); nextMonth() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding(.horizontal)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isPeriodDay: dataManager.getEntry(for: date)?.isPeriodDay ?? false,
                            isFertileDay: dataManager.predictedFertileWindow.contains { calendar.isDate($0, inSameDayAs: date) },
                            isOvulationDay: dataManager.predictedOvulationDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                            isPredictedPeriod: dataManager.predictedPeriodDates.contains { calendar.isDate($0, inSameDayAs: date) },
                            isToday: calendar.isDateInToday(date),
                            hasEntry: dataManager.getEntry(for: date) != nil
                        )
                        .onTapGesture {
                            Haptics.selection()
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: LogView()) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Log Today",
                    color: AppColors.primary
                )
            }
            
            Button(action: { Haptics.selection(); showingPeriodSelector = true }) {
                QuickActionButton(
                    icon: "drop.fill",
                    title: "+ Period",
                    color: AppColors.periodDay
                )
            }
        }
    }
    
    // MARK: - Today's Summary
    
    private func todaySummary(entry: CycleEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Log")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 16) {
                if let mood = entry.mood {
                    VStack {
                        Text(mood.emoji)
                            .font(.title2)
                        Text(mood.rawValue)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                if !entry.symptoms.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Symptoms")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(entry.symptoms.map { $0.rawValue }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                    }
                }
                
                if let temp = entry.temperature {
                    VStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(AppColors.primary)
                        Text(String(format: "%.1f%@", temp, dataManager.settings.temperatureUnit.symbol))
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helper Functions
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return "Today, \(formatter.string(from: date))"
    }
    
    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }
    
    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isPeriodDay: Bool
    let isFertileDay: Bool
    let isOvulationDay: Bool
    let isPredictedPeriod: Bool
    let isToday: Bool
    let hasEntry: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Background for different states
                if isPeriodDay || isPredictedPeriod {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.periodDay.opacity(isPeriodDay ? 1 : 0.3))
                } else if isOvulationDay {
                    Circle()
                        .stroke(AppColors.ovulation, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                } else if isFertileDay {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.fertileDay.opacity(0.3))
                }
                
                // Today indicator
                if isToday {
                    Circle()
                        .fill(AppColors.textPrimary)
                        .frame(width: 30, height: 30)
                }
                
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor)
            }
            .frame(width: 36, height: 36)
            
            // Entry indicator
            if hasEntry && !isPeriodDay {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 44)
    }
    
    private var dayTextColor: Color {
        if isToday {
            return .white
        } else if isPeriodDay {
            return .white
        } else if calendar.isDateInWeekend(date) {
            return AppColors.accent
        }
        return AppColors.textPrimary
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Period Selector View

struct PeriodSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDates: Set<Date> = []
    @State private var displayedMonth = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Instructions
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(AppColors.periodDay)
                    Text("Please select the days of your period")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Calendar
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(0..<3, id: \.self) { monthOffset in
                            let month = calendar.date(byAdding: .month, value: monthOffset, to: startOfCurrentMonth()) ?? Date()
                            MonthSelectorView(
                                month: month,
                                selectedDates: $selectedDates,
                                existingPeriodDays: existingPeriodDays
                            )
                        }
                    }
                    .padding()
                }
                
                // Save Button
                Button(action: { Haptics.selection(); savePeriodDays() }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Save")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.success)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(AppColors.background)
            .navigationTitle(formattedToday())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        Haptics.selection()
                        dismiss()
                    }
                    .foregroundColor(AppColors.periodDay)
                }
            }
            .onAppear {
                loadExistingPeriodDays()
            }
        }
    }
    
    private var existingPeriodDays: Set<Date> {
        Set(dataManager.entries.filter { $0.isPeriodDay }.map { calendar.startOfDay(for: $0.date) })
    }
    
    private func loadExistingPeriodDays() {
        selectedDates = existingPeriodDays
    }
    
    private func startOfCurrentMonth() -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
    }
    
    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return "\(formatter.string(from: Date()))"
    }
    
    private func savePeriodDays() {
        // Add new period days
        let newDates = selectedDates.subtracting(existingPeriodDays)
        dataManager.logPeriodDays(Array(newDates))
        
        // Remove deselected period days
        let removedDates = existingPeriodDays.subtracting(selectedDates)
        for date in removedDates {
            dataManager.removePeriodDay(date)
        }
        
        dismiss()
    }
}

// MARK: - Month Selector View

struct MonthSelectorView: View {
    let month: Date
    @Binding var selectedDates: Set<Date>
    let existingPeriodDays: Set<Date>
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 12) {
            Text(monthYearString())
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            Divider()
            
            // Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        PeriodDayCell(
                            date: date,
                            isSelected: selectedDates.contains(calendar.startOfDay(for: date)),
                            isToday: calendar.isDateInToday(date)
                        )
                        .onTapGesture {
                            Haptics.selection()
                            toggleDate(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: month)
    }
    
    private func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: month)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func toggleDate(_ date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        if selectedDates.contains(normalizedDate) {
            selectedDates.remove(normalizedDate)
        } else {
            selectedDates.insert(normalizedDate)
        }
    }
}

// MARK: - Period Day Cell

struct PeriodDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(AppColors.periodDay)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(.white)
                    .offset(y: 12)
            } else {
                Circle()
                    .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                    .frame(width: 36, height: 36)
            }
            
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? AppColors.periodDay : AppColors.textPrimary))
                .offset(y: isSelected ? -4 : 0)
        }
        .frame(height: 44)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(DataManager())
        .environmentObject(AICompanionManager())
}
