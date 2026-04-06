import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    @Published private(set) var currentHeartRateBpm: Int?
    @Published private(set) var isAuthorized = false

    private let store = HKHealthStore()
    private var query: HKAnchoredObjectQuery?

    private let heartRateType = HKQuantityType(.heartRate)

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let types: Set<HKObjectType> = [heartRateType]
        do {
            try await store.requestAuthorization(toShare: [], read: types)
            isAuthorized = true
            startHeartRateObserver()
        } catch {
            isAuthorized = false
        }
    }

    func startHeartRateObserver() {
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )
        let q = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.handleSamples(samples)
        }
        q.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.handleSamples(samples)
        }
        store.execute(q)
        query = q
    }

    func stopHeartRateObserver() {
        if let q = query { store.stop(q) }
        query = nil
    }

    // nonisolated so HealthKit callbacks (non-main thread) can call this safely
    nonisolated private func handleSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample],
              let latest = quantitySamples.last else { return }
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let bpm = Int(latest.quantity.doubleValue(for: unit))
        Task { @MainActor [weak self] in
            self?.currentHeartRateBpm = bpm
        }
    }
}
