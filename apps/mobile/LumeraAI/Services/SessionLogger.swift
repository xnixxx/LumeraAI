import Foundation

// MARK: - Session Logger

@MainActor
final class SessionLogger: ObservableObject {
    @Published private(set) var currentSession: RunSession?

    private var guidanceEvents: [GuidanceEvent] = []
    private var hazardEvents: [HazardEvent] = []
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func startSession(userId: String, routeId: String, runMode: RunMode) async -> String {
        let sessionId = UUID().uuidString
        currentSession = RunSession(
            id: sessionId,
            userId: userId,
            routeId: routeId,
            runMode: runMode,
            startedAt: Date(),
            endedAt: nil,
            lapCount: 0,
            totalDistanceM: 0,
            averagePaceMpS: 0,
            maxHeartRateBpm: nil,
            averageHeartRateBpm: nil,
            guidanceEvents: [],
            hazardEvents: []
        )
        guidanceEvents = []
        hazardEvents = []

        do {
            try await apiClient.post("/sessions/start", body: StartSessionBody(routeId: routeId, runMode: runMode.rawValue))
        } catch {}

        return sessionId
    }

    func logGuidanceEvent(_ event: GuidanceEvent) {
        guidanceEvents.append(event)
        currentSession?.guidanceEvents = guidanceEvents
    }

    func logHazardEvent(_ event: HazardEvent) {
        hazardEvents.append(event)
        currentSession?.hazardEvents = hazardEvents
    }

    func incrementLap() {
        currentSession?.lapCount += 1
    }

    func updateMetrics(distanceM: Double, paceMpS: Double, heartRateBpm: Int?) {
        currentSession?.totalDistanceM = distanceM
        currentSession?.averagePaceMpS = paceMpS
        if let bpm = heartRateBpm {
            currentSession?.maxHeartRateBpm = max(currentSession?.maxHeartRateBpm ?? 0, bpm)
        }
    }

    func endSession(finalHeartRate: Int?) async -> RunSession? {
        guard var session = currentSession else { return nil }
        session.endedAt = Date()
        session.averageHeartRateBpm = finalHeartRate
        currentSession = session

        let body = EndSessionBody(
            endedAt: ISO8601DateFormatter().string(from: session.endedAt ?? Date()),
            totalDistanceM: session.totalDistanceM,
            lapCount: session.lapCount,
            averagePaceMpS: session.averagePaceMpS
        )
        do {
            try await apiClient.post("/sessions/\(session.id)/end", body: body)
        } catch {}

        return session
    }
}

private struct StartSessionBody: Encodable {
    let routeId: String
    let runMode: String
}

private struct EndSessionBody: Encodable {
    let endedAt: String
    let totalDistanceM: Double
    let lapCount: Int
    let averagePaceMpS: Double
}
