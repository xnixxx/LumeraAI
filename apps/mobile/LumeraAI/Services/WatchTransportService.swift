import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch Semantic Event Transport

@MainActor
final class WatchTransportService: NSObject, ObservableObject {
    @Published private(set) var connectionState: WatchConnectionState = .disconnected

    enum WatchConnectionState {
        case connected, connecting, degraded, disconnected
    }

    private var session: WCSession?
    private var heartbeatTimer: Timer?
    private var lastHeartbeatAt: Date?
    private var reconnectAttempts = 0

    private let heartbeatIntervalSec: TimeInterval = 2.0
    private let heartbeatTimeoutSec: TimeInterval = 6.0
    private let maxReconnectAttempts = 5

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        session = s
        startHeartbeat()
    }

    // MARK: - Send Semantic Event

    func send(semanticType: GuidanceSemanticType, priority: GuidancePriority) {
        guard let session = session, session.isReachable else {
            handleDisconnected()
            return
        }
        let payload: [String: Any] = [
            "eventId": UUID().uuidString,
            "semanticType": semanticType.rawValue,
            "priority": priority.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
        session.sendMessage(payload, replyHandler: nil) { [weak self] error in
            Task { @MainActor in
                self?.handleSendError(error)
            }
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatIntervalSec, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkHeartbeat()
            }
        }
    }

    private func checkHeartbeat() {
        guard let session = session else { return }
        if session.isReachable {
            connectionState = .connected
            lastHeartbeatAt = Date()
            reconnectAttempts = 0
        } else {
            if let last = lastHeartbeatAt, Date().timeIntervalSince(last) > heartbeatTimeoutSec {
                connectionState = .disconnected
                attemptReconnect()
            } else if connectionState == .connected {
                connectionState = .degraded
            }
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else { return }
        reconnectAttempts += 1
        connectionState = .connecting
        session?.activate()
    }

    private func handleDisconnected() {
        connectionState = .disconnected
    }

    private func handleSendError(_ error: Error) {
        connectionState = .degraded
    }
}

// MARK: - WCSessionDelegate

extension WatchTransportService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.connectionState = activationState == .activated ? .connected : .disconnected
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in self.connectionState = .degraded }
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.connectionState = .disconnected
            session.activate()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.connectionState = session.isReachable ? .connected : .disconnected
        }
    }
}
