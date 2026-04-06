import Foundation
import CoreLocation

@MainActor
final class EmergencyService: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var emergencyId: String?

    private let apiClient: APIClient
    private var currentSessionId: String?
    private var lastKnownLocation: CLLocation?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func updateLocation(_ location: CLLocation) {
        lastKnownLocation = location
    }

    func configure(sessionId: String) {
        currentSessionId = sessionId
    }

    func trigger(source: EmergencySource) async {
        guard !isActive, let sessionId = currentSessionId else { return }
        isActive = true
        let id = UUID().uuidString
        emergencyId = id

        let body = EmergencyTriggerBody(
            sessionId: sessionId,
            triggerSource: source.rawValue,
            lastKnownLatitude: lastKnownLocation?.coordinate.latitude,
            lastKnownLongitude: lastKnownLocation?.coordinate.longitude
        )

        do {
            try await apiClient.post("/emergency/trigger", body: body)
        } catch {
            // Log failure — we stay in emergency state regardless of network
        }
    }

    func checkin(isSafe: Bool) async {
        guard let emergencyId else { return }
        let body = EmergencyCheckinBody(emergencyId: emergencyId, safeConfirmed: isSafe)
        do {
            try await apiClient.post("/emergency/checkin", body: body)
            if isSafe { isActive = false }
        } catch {}
    }
}

private struct EmergencyTriggerBody: Encodable {
    let sessionId: String
    let triggerSource: String
    let lastKnownLatitude: Double?
    let lastKnownLongitude: Double?
}

private struct EmergencyCheckinBody: Encodable {
    let emergencyId: String
    let safeConfirmed: Bool
}
