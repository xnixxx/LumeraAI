import WatchKit
import Foundation

// MARK: - Semantic Haptic Player
// Translates semantic guidance events into native WatchKit haptic types.
// Business logic always sends semantic events — never raw haptic calls.

final class SemanticHapticPlayer {
    static let shared = SemanticHapticPlayer()
    private init() {}

    func play(_ semanticType: WatchGuidanceSemanticType) {
        let hapticType = map(semanticType)
        WKInterfaceDevice.current().play(hapticType)

        // Multi-pulse patterns require sequenced calls
        if let pattern = multiPulsePattern(for: semanticType) {
            schedulePattern(pattern)
        }
    }

    // MARK: - Mapping

    private func map(_ type: WatchGuidanceSemanticType) -> WKHapticType {
        switch type {
        case .navLeftSlight:        return .directionUp
        case .navLeftStrong:        return .directionUp
        case .navRightSlight:       return .directionDown
        case .navRightStrong:       return .directionDown
        case .statusOnRoute:        return .success
        case .statusOffRoute:       return .failure
        case .alertHazard:          return .notification
        case .alertSlowDown:        return .retry
        case .alertStop:            return .stop
        case .trainingLapComplete:  return .success
        case .trainingIntervalChange: return .click
        case .systemLowConfidence:  return .navigationGenericManeuver
        case .systemDisconnected:   return .failure
        }
    }

    // Multi-pulse patterns for strong alerts
    private func multiPulsePattern(for type: WatchGuidanceSemanticType) -> [WKHapticType]? {
        switch type {
        case .alertStop:
            return [.stop, .stop, .stop]
        case .navLeftStrong:
            return [.directionUp, .directionUp]
        case .navRightStrong:
            return [.directionDown, .directionDown]
        case .alertHazard:
            return [.notification, .notification, .notification]
        default:
            return nil
        }
    }

    private func schedulePattern(_ pattern: [WKHapticType]) {
        let device = WKInterfaceDevice.current()
        for (index, hapticType) in pattern.enumerated() {
            let delay = Double(index) * 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                device.play(hapticType)
            }
        }
    }
}

// MARK: - Watch Guidance Semantic Type

enum WatchGuidanceSemanticType: String, Codable {
    case navLeftSlight          = "NAV_LEFT_SLIGHT"
    case navLeftStrong          = "NAV_LEFT_STRONG"
    case navRightSlight         = "NAV_RIGHT_SLIGHT"
    case navRightStrong         = "NAV_RIGHT_STRONG"
    case statusOnRoute          = "STATUS_ON_ROUTE"
    case statusOffRoute         = "STATUS_OFF_ROUTE"
    case alertHazard            = "ALERT_HAZARD"
    case alertSlowDown          = "ALERT_SLOW_DOWN"
    case alertStop              = "ALERT_STOP"
    case trainingLapComplete    = "TRAINING_LAP_COMPLETE"
    case trainingIntervalChange = "TRAINING_INTERVAL_CHANGE"
    case systemLowConfidence    = "SYSTEM_LOW_CONFIDENCE"
    case systemDisconnected     = "SYSTEM_DISCONNECTED"
}
