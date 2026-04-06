import Foundation
import Combine

// MARK: - Runtime States

enum RuntimeState: String, Equatable {
    case boot          = "BOOT"
    case idle          = "IDLE"
    case preRunCheck   = "PRE_RUN_CHECK"
    case ready         = "READY"
    case activeRun     = "ACTIVE_RUN"
    case lowConfidence = "LOW_CONFIDENCE"
    case safeMode      = "SAFE_MODE"
    case paused        = "PAUSED"
    case emergency     = "EMERGENCY"
    case sessionComplete = "SESSION_COMPLETE"
    case syncPending   = "SYNC_PENDING"
}

// MARK: - State Machine Events

enum RuntimeEvent {
    case bootComplete
    case startPreCheck
    case preCheckPassed
    case preCheckFailed(reason: String)
    case startRun
    case confidenceDegraded
    case confidenceCritical
    case confidenceRecovered
    case sensorFailure(sensor: String)
    case pause
    case resume
    case emergencyTrigger(source: EmergencySource)
    case endSession
    case syncComplete
    case reset
}

enum EmergencySource: String {
    case userSOS       = "USER_SOS"
    case watchButton   = "WATCH_BUTTON"
    case fallDetected  = "FALL_DETECTED"
    case policyAuto    = "POLICY_AUTO"
}

// MARK: - State Machine

@MainActor
final class RunStateMachine: ObservableObject {
    @Published private(set) var state: RuntimeState = .boot
    @Published private(set) var previousState: RuntimeState? = nil
    @Published private(set) var failureReason: String? = nil
    @Published private(set) var enteredAt: Date = Date()

    private(set) var stateHistory: [(state: RuntimeState, at: Date)] = []

    func send(_ event: RuntimeEvent) {
        guard let nextState = transition(from: state, on: event) else { return }
        stateHistory.append((state: state, at: enteredAt))
        previousState = state
        state = nextState
        enteredAt = Date()
        if case .preCheckFailed(let reason) = event { failureReason = reason }
        else { failureReason = nil }
    }

    var isActiveSession: Bool {
        [.activeRun, .lowConfidence, .safeMode, .paused].contains(state)
    }

    var canGiveGuidance: Bool {
        [.activeRun, .lowConfidence].contains(state)
    }

    // MARK: - Transition Table

    private func transition(from state: RuntimeState, on event: RuntimeEvent) -> RuntimeState? {
        switch (state, event) {
        case (.boot, .bootComplete):                return .idle
        case (.idle, .startPreCheck):               return .preRunCheck
        case (.preRunCheck, .preCheckPassed):       return .ready
        case (.preRunCheck, .preCheckFailed):       return .idle
        case (.ready, .startRun):                   return .activeRun
        case (.activeRun, .confidenceDegraded):     return .lowConfidence
        case (.activeRun, .confidenceCritical):     return .safeMode
        case (.activeRun, .sensorFailure):          return .lowConfidence
        case (.activeRun, .pause):                  return .paused
        case (.activeRun, .emergencyTrigger):       return .emergency
        case (.activeRun, .endSession):             return .sessionComplete
        case (.lowConfidence, .confidenceRecovered): return .activeRun
        case (.lowConfidence, .confidenceCritical): return .safeMode
        case (.lowConfidence, .pause):              return .paused
        case (.lowConfidence, .emergencyTrigger):   return .emergency
        case (.lowConfidence, .endSession):         return .sessionComplete
        case (.safeMode, .confidenceRecovered):     return .activeRun
        case (.safeMode, .pause):                   return .paused
        case (.safeMode, .emergencyTrigger):        return .emergency
        case (.safeMode, .endSession):              return .sessionComplete
        case (.paused, .resume):                    return .activeRun
        case (.paused, .emergencyTrigger):          return .emergency
        case (.paused, .endSession):                return .sessionComplete
        case (.emergency, .endSession):             return .sessionComplete
        case (.sessionComplete, .syncComplete):     return .idle
        case (_, .reset):                           return .idle
        default:                                    return nil
        }
    }
}
