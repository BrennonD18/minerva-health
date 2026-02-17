//
//  LogView.swift
//  WomensHealthApp
//

import SwiftUI

struct LogView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var entry: CycleEntry = CycleEntry()
    @State private var showingDatePicker = false
    @State private var temperatureString = ""
    @State private var showSavedConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date Selector
                    dateSelector
                    
                    // Period Toggle
                    periodSection
                    
                    // Temperature Section (NEW)
                    temperatureSection
                    
                    // Sex Activity
                    sexActivitySection
                    
                    // Mood Section
                    moodSection
                    
                    // Symptoms Section
                    symptomsSection
                    
                    // Discharge Section
                    dischargeSection
                    
                    // Discharge Color (shows when abnormal is selected)
                    if entry.discharge == .abnormal {
                        dischargeColorSection
                    }
                    
                    // Flow Heaviness (shows when period day)
                    if entry.isPeriodDay {
                        flowHeavinessSection
                    }
                    
                    // Notes Section
                    notesSection
                    
                    // Save Button
                    saveButton
                }
                .padding()
            }
            .refreshable {
                Haptics.refresh()
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            .background(AppColors.background)
            .navigationTitle("Add Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if showSavedConfirmation {
                    savedConfirmationBanner
                }
            }
            .onAppear {
                loadExistingEntry()
            }
            .onChange(of: selectedDate) { _, _ in
                loadExistingEntry()
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
        }
    }
    
    // MARK: - Date Selector
    
    private var dateSelector: some View {
        Button(action: { Haptics.selection(); showingDatePicker = true }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(formattedDate(selectedDate))
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    if Calendar.current.isDateInToday(selectedDate) {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.primary)
            }
            .padding()
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Period Section
    
    private var periodSection: some View {
        SectionContainer(title: "Period Day") {
            Toggle(isOn: $entry.isPeriodDay) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(AppColors.periodDay)
                    Text("Mark as period day")
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .tint(AppColors.periodDay)
        }
    }
    
    // MARK: - Temperature Section (NEW FEATURE)
    
    private var temperatureSection: some View {
        SectionContainer(title: "Basal Body Temperature (Optional)") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    TextField("Enter temperature", text: $temperatureString)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: temperatureString) { _, newValue in
                            if let temp = Double(newValue) {
                                entry.temperature = temp
                            } else if newValue.isEmpty {
                                entry.temperature = nil
                            }
                        }
                    
                    Text(dataManager.settings.temperatureUnit.symbol)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Quick temperature buttons
                HStack(spacing: 8) {
                    ForEach(quickTemperatureOptions, id: \.self) { temp in
                        Button(action: {
                            Haptics.selection()
                            temperatureString = String(format: "%.1f", temp)
                            entry.temperature = temp
                        }) {
                            Text(String(format: "%.1f", temp))
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    entry.temperature == temp ?
                                    AppColors.primary : AppColors.secondary
                                )
                                .foregroundColor(
                                    entry.temperature == temp ?
                                    .white : AppColors.textPrimary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Text("Tracking BBT can help identify ovulation patterns")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private var quickTemperatureOptions: [Double] {
        // Common BBT range
        if dataManager.settings.temperatureUnit == .celsius {
            return [36.0, 36.3, 36.5, 36.7, 37.0]
        } else {
            return [97.0, 97.5, 98.0, 98.5, 99.0]
        }
    }
    
    // MARK: - Sex Activity Section
    
    private var sexActivitySection: some View {
        SectionContainer(title: "Sex") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(SexActivity.allCases, id: \.self) { activity in
                    SelectableChip(
                        title: activity.rawValue,
                        icon: activity.icon,
                        isSelected: entry.sexActivity == activity,
                        action: {
                            entry.sexActivity = entry.sexActivity == activity ? nil : activity
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Mood Section
    
    private var moodSection: some View {
        SectionContainer(title: "Mood") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        MoodChip(
                            mood: mood,
                            isSelected: entry.mood == mood,
                            action: {
                                entry.mood = entry.mood == mood ? nil : mood
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Symptoms Section
    
    private var symptomsSection: some View {
        SectionContainer(title: "Symptoms") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Symptom.allCases, id: \.self) { symptom in
                    SelectableChip(
                        title: symptom.rawValue,
                        icon: symptom.icon,
                        isSelected: entry.symptoms.contains(symptom),
                        action: {
                            if entry.symptoms.contains(symptom) {
                                entry.symptoms.removeAll { $0 == symptom }
                            } else {
                                // If selecting "Everything's fine", clear other symptoms
                                if symptom == .everythingsFine {
                                    entry.symptoms = [symptom]
                                } else {
                                    // Remove "Everything's fine" if selecting other symptoms
                                    entry.symptoms.removeAll { $0 == .everythingsFine }
                                    entry.symptoms.append(symptom)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Discharge Section
    
    private var dischargeSection: some View {
        SectionContainer(title: "Discharge") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DischargeType.allCases, id: \.self) { discharge in
                    SelectableChip(
                        title: discharge.rawValue,
                        isSelected: entry.discharge == discharge,
                        subtitle: discharge.description,
                        action: {
                            if entry.discharge == discharge {
                                entry.discharge = nil
                                entry.dischargeColor = nil
                            } else {
                                entry.discharge = discharge
                                // Clear color if not abnormal
                                if discharge != .abnormal {
                                    entry.dischargeColor = nil
                                }
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Discharge Color Section (NEW - for abnormal discharge)
    
    private var dischargeColorSection: some View {
        SectionContainer(title: "Discharge Color") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select the color to help track patterns and identify potential concerns")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(DischargeColor.allCases, id: \.self) { color in
                        DischargeColorChip(
                            color: color,
                            isSelected: entry.dischargeColor == color,
                            action: {
                                entry.dischargeColor = entry.dischargeColor == color ? nil : color
                            }
                        )
                    }
                }
                
                // Health note for selected color
                if let selectedColor = entry.dischargeColor {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppColors.accent)
                        Text(selectedColor.healthNote)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                    .background(AppColors.secondary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    // MARK: - Flow Heaviness Section
    
    private var flowHeavinessSection: some View {
        SectionContainer(title: "Heaviness of Flow") {
            HStack(spacing: 16) {
                ForEach(FlowHeaviness.allCases, id: \.self) { heaviness in
                    FlowChip(
                        heaviness: heaviness,
                        isSelected: entry.flowHeaviness == heaviness,
                        action: {
                            entry.flowHeaviness = entry.flowHeaviness == heaviness ? nil : heaviness
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        SectionContainer(title: "Notes") {
            TextEditor(text: Binding(
                get: { entry.notes ?? "" },
                set: { entry.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(minHeight: 100)
            .padding(8)
            .background(AppColors.secondary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: { Haptics.selection(); saveEntry() }) {
            HStack {
                Image(systemName: showSavedConfirmation ? "checkmark.circle.fill" : "checkmark")
                Text(showSavedConfirmation ? "Saved!" : "Save")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(showSavedConfirmation ? AppColors.success.opacity(0.9) : AppColors.success)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(showSavedConfirmation)
    }
    
    private var savedConfirmationBanner: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text("Log saved")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.success)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.top, 8)
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Helper Functions
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func loadExistingEntry() {
        if let existingEntry = dataManager.getEntry(for: selectedDate) {
            entry = existingEntry
            if let temp = entry.temperature {
                temperatureString = String(format: "%.1f", temp)
            } else {
                temperatureString = ""
            }
        } else {
            entry = CycleEntry(date: selectedDate)
            temperatureString = ""
        }
    }
    
    private func saveEntry() {
        entry.date = selectedDate
        dataManager.addEntry(entry)
        Haptics.success()
        
        withAnimation(.easeOut(duration: 0.2)) {
            showSavedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.25)) {
                showSavedConfirmation = false
            }
        }
    }
}

// MARK: - Section Container

struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Selectable Chip

struct SelectableChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var subtitle: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppColors.primary : AppColors.secondary)
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Mood Chip

struct MoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.rawValue)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? mood.color : AppColors.secondary)
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Flow Chip

struct FlowChip: View {
    let heaviness: FlowHeaviness
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            VStack(spacing: 6) {
                Image(systemName: heaviness.icon)
                    .font(.title2)
                Text(heaviness.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? heaviness.color : AppColors.secondary)
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Discharge Color Chip (NEW)

struct DischargeColorChip: View {
    let color: DischargeColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            HStack(spacing: 8) {
                // Color indicator circle
                Circle()
                    .fill(color.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text(color.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.secondary)
            .foregroundColor(AppColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(AppColors.primary)
            .padding()
            .onChange(of: selectedDate) { _, _ in
                Haptics.selection()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Haptics.selection()
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LogView()
        .environmentObject(DataManager())
}
