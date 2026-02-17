//
//  StatisticsView.swift
//  WomensHealthApp
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    summaryCards
                    
                    // Temperature Chart
                    if !dataManager.temperatureData.isEmpty {
                        temperatureChart
                    }
                    
                    // Cycle History
                    cycleHistory
                }
                .padding()
            }
            .refreshable {
                Haptics.refresh()
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            .background(AppColors.background)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Average duration of cycle",
                    value: "\(dataManager.averageCycleLength) days",
                    icon: "arrow.triangle.2.circlepath",
                    color: AppColors.accent
                )
                
                StatCard(
                    title: "Average duration of period",
                    value: "\(dataManager.averagePeriodLength) days",
                    icon: "drop.fill",
                    color: AppColors.periodDay
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Cycles logged",
                    value: "\(dataManager.cycles.count)",
                    icon: "calendar",
                    color: AppColors.primary
                )
                
                StatCard(
                    title: "Days tracked",
                    value: "\(dataManager.entries.count)",
                    icon: "checkmark.circle.fill",
                    color: AppColors.success
                )
            }
        }
    }
    
    // MARK: - Temperature Chart
    
    private var temperatureChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(AppColors.primary)
                Text("Basal Body Temperature")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            if dataManager.temperatureData.count >= 2 {
                Chart {
                    ForEach(dataManager.temperatureData, id: \.0) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.0),
                            y: .value("Temperature", dataPoint.1)
                        )
                        .foregroundStyle(AppColors.primary)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", dataPoint.0),
                            y: .value("Temperature", dataPoint.1)
                        )
                        .foregroundStyle(AppColors.primary)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: temperatureRange)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let temp = value.as(Double.self) {
                                Text(String(format: "%.1f", temp))
                            }
                        }
                    }
                }
            } else {
                Text("Log at least 2 temperature readings to see your chart")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
            
            // Temperature insight
            if let avgTemp = averageTemperature {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppColors.accent)
                    Text("Average: \(String(format: "%.2f", avgTemp))\(dataManager.settings.temperatureUnit.symbol)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var temperatureRange: ClosedRange<Double> {
        let temps = dataManager.temperatureData.map { $0.1 }
        let minTemp = (temps.min() ?? 36.0) - 0.5
        let maxTemp = (temps.max() ?? 37.5) + 0.5
        return minTemp...maxTemp
    }
    
    private var averageTemperature: Double? {
        let temps = dataManager.temperatureData.map { $0.1 }
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }
    
    // MARK: - Cycle History
    
    private var cycleHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("History")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(dataManager.cycles.count) cycles logged")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if dataManager.cycles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No cycles logged yet")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Start tracking your period to see your cycle history here")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(dataManager.cycles) { cycle in
                    CycleHistoryCard(cycle: cycle, isCurrentCycle: cycle.id == dataManager.currentCycle?.id)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Cycle History Card

struct CycleHistoryCard: View {
    let cycle: Cycle
    let isCurrentCycle: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(cycleTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                if isCurrentCycle {
                    Text("(Current cycle)")
                        .font(.caption)
                        .foregroundColor(AppColors.accent)
                }
                
                Spacer()
                
                if let length = cycle.cycleLength {
                    Text("\(length) days")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.secondary)
                        .frame(height: 8)
                    
                    // Period days
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.periodDay)
                        .frame(width: periodWidth(totalWidth: geometry.size.width), height: 8)
                    
                    // Fertile window (if not current cycle)
                    if !isCurrentCycle, cycle.ovulationDate != nil, let cycleLength = cycle.cycleLength {
                        let ovulationPosition = ovulationOffset(totalWidth: geometry.size.width, cycleLength: cycleLength)
                        
                        // Fertile window
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.fertileDay)
                            .frame(width: geometry.size.width * 0.2, height: 8)
                            .offset(x: ovulationPosition - geometry.size.width * 0.15)
                        
                        // Ovulation dot
                        Circle()
                            .fill(AppColors.ovulation)
                            .frame(width: 12, height: 12)
                            .offset(x: ovulationPosition - 6, y: -2)
                    }
                }
            }
            .frame(height: 12)
            
            // Legend
            HStack {
                Text("\(cycle.periodLength) days")
                    .font(.caption)
                    .foregroundColor(AppColors.periodDay)
                
                Spacer()
                
                if isCurrentCycle {
                    let dayCount = calendar.dateComponents([.day], from: cycle.startDate, to: Date()).day ?? 0
                    Text("\(dayCount + 1) days")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppColors.secondary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var cycleTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let start = formatter.string(from: cycle.startDate)
        
        if let end = cycle.endDate {
            formatter.dateFormat = "MMM d"
            return "\(start) - \(formatter.string(from: end))"
        } else {
            return "\(start)"
        }
    }
    
    private func periodWidth(totalWidth: CGFloat) -> CGFloat {
        guard let cycleLength = cycle.cycleLength, cycleLength > 0 else {
            return totalWidth * 0.2 // Default for current cycle
        }
        return totalWidth * CGFloat(cycle.periodLength) / CGFloat(cycleLength)
    }
    
    private func ovulationOffset(totalWidth: CGFloat, cycleLength: Int) -> CGFloat {
        let ovulationDay = cycleLength - 14
        return totalWidth * CGFloat(ovulationDay) / CGFloat(cycleLength)
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .environmentObject(DataManager())
}
