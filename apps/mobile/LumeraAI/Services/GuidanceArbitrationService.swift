import Foundation
import CoreLocation
import Combine

// MARK: - Guidance Arbitration Service

@MainActor
final class GuidanceArbitrationService: ObservableObject {
    @Published private(set) var lastDecision: GuidanceDecision?

    private var lastGuidanceTimestamps: [GuidanceSemanticType: Date] = [:]
    private var lastDirectionType: GuidanceSemanticType? = nil
    private var lastDirectionAt: Date? = nil

    private let directionCooldownSec: TimeInterval = 2.0
    private let hazardCooldownSec: TimeInterval = 3.0
    private let hysteresisM: Double = 0.10

    // Called every time sensor fusion produces a new state
    func evaluate(
        runtimeState: RuntimeState,
        deviationFromCenterM: Double,
        onSoftCorridor: Bool,
        outsideCorridor: Bool,
        detectedHazards: [HazardInput],
        confidence: ConfidenceState,
        emergencyActive: Bool
    ) -> GuidanceDecision? {
        if emergencyActive {
            return emit(.alertStop, priority: .emergencyStop, confidence: confidence)
        }

        // P0: Critical hazard imminent
        if let h = detectedHazards.first(where: { $0.severity == .critical && $0.distanceM < 2.0 }) {
            _ = h
            return emit(.alertStop, priority: .emergencyStop, confidence: confidence)
        }

        // P1: High hazard avoidance
        if detectedHazards.contains(where: { $0.severity == .high || $0.severity == .critical }) {
            return emitWithCooldown(.alertHazard, cooldownSec: hazardCooldownSec, priority: .hazardAvoidance, confidence: confidence)
        }

        // P2: Route correction (only when guidance is appropriate)
        if runtimeState == .activeRun || runtimeState == .lowConfidence {
            if let correction = computeRouteCorrection(deviationFromCenterM: deviationFromCenterM, outsideCorridor: outsideCorridor, confidence: confidence) {
                return correction
            }
        }

        // P3: System low confidence notification
        if confidence.band == .critical {
            return emitWithCooldown(.systemLowConfidence, cooldownSec: 10, priority: .informational, confidence: confidence)
        }

        return nil
    }

    // MARK: - Route Correction

    private func computeRouteCorrection(
        deviationFromCenterM: Double,
        outsideCorridor: Bool,
        confidence: ConfidenceState
    ) -> GuidanceDecision? {
        let abs = Swift.abs(deviationFromCenterM)
        guard abs > 0.20 else { return nil } // on-course threshold

        let isRight = deviationFromCenterM > 0
        let semanticType: GuidanceSemanticType
        if abs >= 0.80 {
            semanticType = isRight ? .navLeftStrong : .navRightStrong
        } else {
            semanticType = isRight ? .navLeftSlight : .navRightSlight
        }

        // Anti-oscillation
        let now = Date()
        if let lastDir = lastDirectionType, let lastAt = lastDirectionAt, lastDir == semanticType {
            if now.timeIntervalSince(lastAt) < directionCooldownSec { return nil }
        }

        return emitDirection(semanticType, confidence: confidence)
    }

    // MARK: - Emission Helpers

    private func emit(_ type: GuidanceSemanticType, priority: GuidancePriority, confidence: ConfidenceState) -> GuidanceDecision {
        let decision = GuidanceDecision(semanticType: type, priority: priority, confidence: confidence)
        lastDecision = decision
        lastGuidanceTimestamps[type] = Date()
        return decision
    }

    private func emitWithCooldown(_ type: GuidanceSemanticType, cooldownSec: TimeInterval, priority: GuidancePriority, confidence: ConfidenceState) -> GuidanceDecision? {
        if let last = lastGuidanceTimestamps[type], Date().timeIntervalSince(last) < cooldownSec { return nil }
        return emit(type, priority: priority, confidence: confidence)
    }

    private func emitDirection(_ type: GuidanceSemanticType, confidence: ConfidenceState) -> GuidanceDecision {
        lastDirectionType = type
        lastDirectionAt = Date()
        return emit(type, priority: .routeCorrection, confidence: confidence)
    }
}

// MARK: - Supporting Types

struct HazardInput {
    let hazardType: HazardType
    let severity: HazardSeverity
    let distanceM: Double
    let bearing: Double
}

struct GuidanceDecision {
    let semanticType: GuidanceSemanticType
    let priority: GuidancePriority
    let confidence: ConfidenceState
}
