//
//  HealthKitManager.swift
//  WomensHealthApp
//

import Foundation
import HealthKit
import Combine

/// Manages reading and writing cycle-related data to Apple Health.
/// Request authorization in Settings; writes happen when the user saves a log.
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined

    private var menstrualFlowCategoryType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .menstrualFlow)
    }
    private var sexualActivityType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sexualActivity)
    }
    private var basalBodyTemperatureType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .basalBodyTemperature)
    }

    private init() {}

    /// Call from main thread. HealthKit is only available on iPhone (not iPad for some types) and when device supports it.
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Types to request

    private var typesToWrite: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        if let menstrual = menstrualFlowCategoryType { types.insert(menstrual) }
        if let sexual = sexualActivityType { types.insert(sexual) }
        if let bbt = basalBodyTemperatureType { types.insert(bbt) }
        return types
    }

    private var typesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let menstrual = menstrualFlowCategoryType { types.insert(menstrual) }
        if let sexual = sexualActivityType { types.insert(sexual) }
        if let bbt = basalBodyTemperatureType { types.insert(bbt) }
        return types
    }

    // MARK: - Authorization

    /// Request HealthKit authorization. Present this when the user taps "Connect to Apple Health".
    func requestAuthorization() async {
        guard isHealthDataAvailable else {
            await MainActor.run { isAuthorized = false }
            return
        }
        guard let menstrual = menstrualFlowCategoryType else {
            await MainActor.run { isAuthorized = false }
            return
        }

        let typesToRead = typesToRead
        let typesToWrite = typesToWrite

        do {
            try await store.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            let status = store.authorizationStatus(for: menstrual)
            await MainActor.run {
                authorizationStatus = status
                isAuthorized = (status == .sharingAuthorized)
            }
        } catch {
            await MainActor.run { isAuthorized = false }
        }
    }

    /// Call once at launch to refresh authorization state (e.g. user may have toggled in Settings app).
    func refreshAuthorizationStatus() {
        guard isHealthDataAvailable, let menstrual = menstrualFlowCategoryType else {
            isAuthorized = false
            return
        }
        authorizationStatus = store.authorizationStatus(for: menstrual)
        isAuthorized = (authorizationStatus == .sharingAuthorized)
    }

    // MARK: - Write: Menstrual flow

    /// Write one day of menstrual flow to Health. Call when user saves a log with period day and optional flow.
    func writeMenstrualFlow(date: Date, flow: FlowHeaviness?) {
        guard isHealthDataAvailable, let type = menstrualFlowCategoryType else { return }
        guard store.authorizationStatus(for: type) == .sharingAuthorized else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        // Menstrual flow category raw values: 0=unspecified, 1=light, 2=medium, 3=heavy
        let value = flow?.hkCategoryValue ?? 0
        let sample = HKCategorySample(
            type: type,
            value: value,
            start: start,
            end: end
        )

        store.save(sample) { _, _ in }
    }

    /// Remove menstrual flow for a given day (e.g. user unmarked period day).
    func deleteMenstrualFlow(for date: Date) {
        guard isHealthDataAvailable, let type = menstrualFlowCategoryType else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak store] _, samples, _ in
            guard let store = store, let samples = samples as? [HKCategorySample], !samples.isEmpty else { return }
            store.delete(samples) { _, _ in }
        }
        store.execute(query)
    }

    // MARK: - Write: Sexual activity

    func writeSexualActivity(date: Date) {
        guard isHealthDataAvailable, let type = sexualActivityType else { return }
        guard store.authorizationStatus(for: type) == .sharingAuthorized else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        // Category value 0 = unspecified (HKCategoryValueSexualActivity removed in newer SDKs)
        let sample = HKCategorySample(
            type: type,
            value: 0,
            start: start,
            end: end
        )
        store.save(sample) { _, _ in }
    }

    func deleteSexualActivity(for date: Date) {
        guard isHealthDataAvailable, let type = sexualActivityType else { return }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak store] _, samples, _ in
            guard let store = store, let samples = samples as? [HKCategorySample], !samples.isEmpty else { return }
            store.delete(samples) { _, _ in }
        }
        store.execute(query)
    }

    // MARK: - Write: Basal body temperature

    func writeBasalBodyTemperature(date: Date, celsius: Double) {
        guard isHealthDataAvailable, let type = basalBodyTemperatureType else { return }
        guard store.authorizationStatus(for: type) == .sharingAuthorized else { return }

        let quantity = HKQuantity(unit: .degreeCelsius(), doubleValue: celsius)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        store.save(sample) { _, _ in }
    }
}

// MARK: - FlowHeaviness → HealthKit

private extension FlowHeaviness {
    /// HealthKit menstrual flow category raw values: 1=light, 2=medium, 3=heavy
    var hkCategoryValue: Int {
        switch self {
        case .light: return 1
        case .medium: return 2
        case .heavy: return 3
        }
    }
}
