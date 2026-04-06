import AVFoundation
import Foundation

// MARK: - Audio Cue Service (sparse, accessibility-first)

@MainActor
final class AudioCueService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenAt: [String: Date] = [:]
    private let minIntervalSec: TimeInterval = 4.0

    var voiceFeedbackEnabled = true
    var preferredLanguage = "en-US"
    var volume: Float = 0.9

    // MARK: - Navigation Cues

    func announce(_ semanticType: GuidanceSemanticType) {
        guard voiceFeedbackEnabled else { return }
        let (text, cooldown) = cueText(for: semanticType)
        speak(text, key: semanticType.rawValue, cooldownSec: cooldown)
    }

    // MARK: - Metrics

    func announcePace(paceMpS: Double) {
        guard voiceFeedbackEnabled else { return }
        let minPerKm = paceMpS > 0 ? 1000.0 / (paceMpS * 60.0) : 0
        let min = Int(minPerKm)
        let sec = Int((minPerKm - Double(min)) * 60)
        speak("\(min) minutes \(sec) seconds per kilometre", key: "pace", cooldownSec: 30)
    }

    func announceHeartRate(_ bpm: Int) {
        guard voiceFeedbackEnabled else { return }
        speak("Heart rate \(bpm)", key: "hr", cooldownSec: 20)
    }

    func announceDistance(_ distanceM: Double) {
        guard voiceFeedbackEnabled else { return }
        let km = distanceM / 1000.0
        speak(String(format: "%.2f kilometres", km), key: "dist", cooldownSec: 30)
    }

    func announceLap(_ lapNumber: Int) {
        speak("Lap \(lapNumber) complete", key: "lap_\(lapNumber)", cooldownSec: 0)
    }

    func announceSessionSummary(session: RunSession) {
        let text = buildSummary(session: session)
        synthesizer.stopSpeaking(at: .immediate)
        speak(text, key: "summary", cooldownSec: 0)
    }

    func announceConfidenceDegraded() {
        speak("Guidance quality reduced. Proceed with caution.", key: "low_conf", cooldownSec: 10)
    }

    func announceSafeMode() {
        speak("Safe mode active. Slow down.", key: "safe_mode", cooldownSec: 15)
    }

    func announceWatchDisconnected() {
        speak("Watch disconnected. Audio guidance active.", key: "watch_disc", cooldownSec: 10)
    }

    func announceEmergency() {
        synthesizer.stopSpeaking(at: .immediate)
        speak("Emergency activated. Help is being notified.", key: "emergency", cooldownSec: 0)
    }

    // MARK: - Private

    private func cueText(for type: GuidanceSemanticType) -> (String, TimeInterval) {
        switch type {
        case .navLeftSlight:        return ("Slight left", 3.0)
        case .navLeftStrong:        return ("Turn left", 2.0)
        case .navRightSlight:       return ("Slight right", 3.0)
        case .navRightStrong:       return ("Turn right", 2.0)
        case .statusOffRoute:       return ("Off route", 4.0)
        case .alertHazard:          return ("Hazard ahead", 3.0)
        case .alertSlowDown:        return ("Slow down", 2.0)
        case .alertStop:            return ("Stop now", 0.0)
        case .trainingLapComplete:  return ("Lap complete", 0.0)
        case .systemLowConfidence:  return ("Guidance reduced", 8.0)
        case .systemDisconnected:   return ("Watch disconnected", 5.0)
        default:                    return ("", 999.0)
        }
    }

    private func speak(_ text: String, key: String, cooldownSec: TimeInterval) {
        guard !text.isEmpty else { return }
        if cooldownSec > 0 {
            if let last = lastSpokenAt[key], Date().timeIntervalSince(last) < cooldownSec { return }
        }
        lastSpokenAt[key] = Date()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: preferredLanguage)
        utterance.volume = volume
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }

    private func buildSummary(session: RunSession) -> String {
        let km = session.totalDistanceM / 1000.0
        let minPerKm = session.averagePaceMpS > 0 ? 1000.0 / (session.averagePaceMpS * 60.0) : 0
        let min = Int(minPerKm)
        let sec = Int((minPerKm - Double(min)) * 60)
        var parts = [
            "Run complete.",
            String(format: "Distance: %.2f kilometres.", km),
            "\(session.lapCount) laps.",
            "Average pace: \(min) minutes \(sec) seconds per kilometre.",
        ]
        if let hr = session.averageHeartRateBpm {
            parts.append("Average heart rate: \(hr) beats per minute.")
        }
        return parts.joined(separator: " ")
    }
}
