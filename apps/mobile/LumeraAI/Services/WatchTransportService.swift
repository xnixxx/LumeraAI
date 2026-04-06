import Foundation
import WatchConnectivity

// MARK: - Watch Semantic Event Transport

final class WatchTransportService: NSObject, ObservableObject {
    @Published private(set) var connectionState: WatchConnectionState = .disconnected

    enum WatchConnectionState {
        case connected, connecting, degraded, disconnected
    }

    private var heartbeatTimer: Timer?
    private var lastHeartbeatAt: Date?
    private var reconnectAttempts = 0

    private let heartbeatIntervalSec: TimeInterval = 2.0
    private let heartbeatTimeoutSec: TimeInterval = 6.0
    private let maxReconnectAttempts = 5

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        startHeartbeat()
    }

    // MARK: - Send Semantic Event

    func send(semanticType: GuidanceSemanticType, priority: GuidancePriority) {
        guard WCSession.default.isReachable else {
            DispatchQueue.main.async { self.connectionState = .disconnected }
            return
        }
        let payload: [String: Any] = [
            "eventId": UUID().uuidString,
            "semanticType": semanticType.rawValue,
            "priority": priority.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
        WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] _ in
            DispatchQueue.main.async { self?.connectionState = .degraded }
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatIntervalSec, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.checkHeartbeat() }
        }
    }

    private func checkHeartbeat() {
        if WCSession.default.isReachable {
            connectionState = .connected
            lastHeartbeatAt = Date()
            reconnectAttempts = 0
        } else if let last = lastHeartbeatAt,
                  Date().timeIntervalSince(last) > heartbeatTimeoutSec {
            connectionState = .disconnected
            attemptReconnect()
        } else if connectionState == .connected {
            connectionState = .degraded
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else { return }
        reconnectAttempts += 1
        connectionState = .connecting
        WCSession.default.activate()
    }
}

// MARK: - WCSessionDelegate

extension WatchTransportService: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.connectionState = state == .activated ? .connected : .disconnected
        }
    }

    // iOS-only delegate methods
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async { self.connectionState = .degraded }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { self.connectionState = .disconnected }
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionState = session.isReachable ? .connected : .disconnected
        }
    }
}
