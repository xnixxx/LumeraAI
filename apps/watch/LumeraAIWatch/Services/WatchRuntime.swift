import Foundation
import WatchKit
import WatchConnectivity
import Combine

// MARK: - Watch Runtime (coordinator for the watch app)

@MainActor
final class WatchRuntime: NSObject, ObservableObject {
    @Published private(set) var sessionState: WatchSessionState = .idle
    @Published private(set) var lastSemanticEvent: WatchGuidanceSemanticType?
    @Published private(set) var phoneConnected = false
    @Published private(set) var heartRateBpm: Int?
    @Published private(set) var lapCount = 0
    @Published private(set) var distanceM: Double = 0

    private let hapticPlayer = SemanticHapticPlayer.shared
    private var heartbeatTimer: Timer?
    private var lastPhoneMessageAt: Date?

    enum WatchSessionState: String {
        case idle       = "IDLE"
        case activeRun  = "ACTIVE_RUN"
        case lowConf    = "LOW_CONFIDENCE"
        case safeMode   = "SAFE_MODE"
        case paused     = "PAUSED"
        case emergency  = "EMERGENCY"
    }

    override init() {
        super.init()
        activateWatchConnectivity()
        startConnectionMonitor()
    }

    // MARK: - Watch Connectivity

    private func activateWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Connection Monitor

    private func startConnectionMonitor() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPhoneConnection()
            }
        }
    }

    private func checkPhoneConnection() {
        if let last = lastPhoneMessageAt, Date().timeIntervalSince(last) > 6.0 {
            phoneConnected = false
            hapticPlayer.play(.systemDisconnected)
        }
    }

    // MARK: - Commands to Phone

    func sendPauseCommand() {
        sendCommand("PAUSE")
    }

    func sendResumeCommand() {
        sendCommand("RESUME")
    }

    func sendSOSCommand() {
        sendCommand("SOS")
        hapticPlayer.play(.alertStop)
    }

    func sendEndSessionCommand() {
        sendCommand("END_SESSION")
    }

    func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["command": command, "timestamp": ISO8601DateFormatter().string(from: Date())],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    func sendSafeCheckinCommand() {
        sendCommand("SAFE_CHECKIN")
    }

    // MARK: - Process Incoming Events from Phone

    func processIncomingMessage(_ message: [String: Any]) {
        lastPhoneMessageAt = Date()
        phoneConnected = true

        if let stateRaw = message["runtimeState"] as? String {
            updateSessionState(stateRaw)
        }

        if let eventRaw = message["semanticType"] as? String,
           let semanticType = WatchGuidanceSemanticType(rawValue: eventRaw) {
            hapticPlayer.play(semanticType)
            lastSemanticEvent = semanticType
        }

        if let bpm = message["heartRateBpm"] as? Int { heartRateBpm = bpm }
        if let laps = message["lapCount"] as? Int { lapCount = laps }
        if let dist = message["distanceM"] as? Double { distanceM = dist }
    }

    private func updateSessionState(_ raw: String) {
        switch raw {
        case "ACTIVE_RUN":        sessionState = .activeRun
        case "LOW_CONFIDENCE":    sessionState = .lowConf
        case "SAFE_MODE":         sessionState = .safeMode
        case "PAUSED":            sessionState = .paused
        case "EMERGENCY":
            sessionState = .emergency
            hapticPlayer.play(.alertStop)
        default:                  sessionState = .idle
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchRuntime: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.phoneConnected = activationState == .activated
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.processIncomingMessage(message)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.phoneConnected = session.isReachable
            if !session.isReachable {
                self.hapticPlayer.play(.systemDisconnected)
            }
        }
    }
}
