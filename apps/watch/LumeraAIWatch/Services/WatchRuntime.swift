import Foundation
import WatchKit
import WatchConnectivity

// MARK: - Watch Runtime

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
        activateSession()
        startHeartbeat()
    }

    // MARK: - WatchConnectivity

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.checkConnection() }
        }
    }

    private func checkConnection() {
        guard let last = lastPhoneMessageAt else { return }
        if Date().timeIntervalSince(last) > 6.0 {
            phoneConnected = false
            hapticPlayer.play(.systemDisconnected)
        }
    }

    // MARK: - Commands to Phone

    func sendPauseCommand()        { sendCommand("PAUSE") }
    func sendResumeCommand()       { sendCommand("RESUME") }
    func sendEndSessionCommand()   { sendCommand("END_SESSION") }
    func sendSafeCheckinCommand()  { sendCommand("SAFE_CHECKIN") }

    func sendSOSCommand() {
        sendCommand("SOS")
        hapticPlayer.play(.alertStop)
    }

    func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["command": command, "timestamp": ISO8601DateFormatter().string(from: Date())],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    // MARK: - Incoming Messages

    private func handleMessage(_ message: [String: Any]) {
        lastPhoneMessageAt = Date()
        phoneConnected = true

        if let stateRaw = message["runtimeState"] as? String {
            updateState(stateRaw)
        }
        if let eventRaw = message["semanticType"] as? String,
           let event = WatchGuidanceSemanticType(rawValue: eventRaw) {
            hapticPlayer.play(event)
            lastSemanticEvent = event
        }
        if let bpm  = message["heartRateBpm"] as? Int    { heartRateBpm = bpm }
        if let laps = message["lapCount"]     as? Int    { lapCount = laps }
        if let dist = message["distanceM"]   as? Double { distanceM = dist }
    }

    private func updateState(_ raw: String) {
        switch raw {
        case "ACTIVE_RUN":     sessionState = .activeRun
        case "LOW_CONFIDENCE": sessionState = .lowConf
        case "SAFE_MODE":      sessionState = .safeMode
        case "PAUSED":         sessionState = .paused
        case "EMERGENCY":
            sessionState = .emergency
            hapticPlayer.play(.alertStop)
        default:               sessionState = .idle
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchRuntime: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.phoneConnected = (state == .activated)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.handleMessage(message) }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.phoneConnected = session.isReachable
            if !session.isReachable {
                self.hapticPlayer.play(.systemDisconnected)
            }
        }
    }
}
