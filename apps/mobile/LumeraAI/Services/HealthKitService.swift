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
            self?.processSamples(samples)
        }
        q.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processSamples(samples)
        }
        store.execute(q)
        query = q
    }

    func stopHeartRateObserver() {
        if let q = query { store.stop(q) }
        query = nil
    }

    private func processSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample],
              let latest = quantitySamples.last else { return }
        let bpm = Int(latest.quantity.doubleValue(for: .init(from: "count/min")))
        Task { @MainActor in
            self.currentHeartRateBpm = bpm
        }
    }
}
