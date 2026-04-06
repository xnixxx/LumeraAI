import UIKit
import CoreHaptics

// MARK: - Haptic Service (iPhone-side supplemental haptics)

final class HapticService {
    private var engine: CHHapticEngine?

    init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {}
    }

    func play(_ semanticType: GuidanceSemanticType) {
        switch semanticType {
        case .alertStop:
            playPattern(intensity: 1.0, sharpness: 0.8, count: 3, duration: 0.4)
        case .alertHazard:
            playPattern(intensity: 1.0, sharpness: 0.9, count: 3, duration: 0.1)
        case .alertSlowDown:
            playPattern(intensity: 0.9, sharpness: 0.7, count: 2, duration: 0.15)
        case .navLeftStrong, .navRightStrong:
            playPattern(intensity: 0.9, sharpness: 0.6, count: 2, duration: 0.12)
        case .navLeftSlight, .navRightSlight:
            playPattern(intensity: 0.5, sharpness: 0.5, count: 1, duration: 0.08)
        case .statusOffRoute:
            playPattern(intensity: 0.8, sharpness: 0.6, count: 2, duration: 0.2)
        case .trainingLapComplete:
            playPattern(intensity: 0.6, sharpness: 0.4, count: 3, duration: 0.08)
        case .systemLowConfidence:
            playPattern(intensity: 0.5, sharpness: 0.3, count: 2, duration: 0.3)
        default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func playPattern(intensity: Float, sharpness: Float, count: Int, duration: TimeInterval) {
        guard let engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        var events: [CHHapticEvent] = []
        for i in 0..<count {
            let start = TimeInterval(i) * (duration + 0.06)
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: start,
                duration: duration
            ))
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}
