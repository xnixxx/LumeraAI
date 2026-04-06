import {
  GuidanceSemanticType,
  GuidancePriority,
  GuidanceDecision,
  ConfidenceState,
  ConfidenceBand,
  CorridorEstimate,
  NormalizedHazard,
  HazardSeverity,
  RuntimeState,
} from "@lumera/domain";
import { CORRIDOR_THRESHOLDS, ANTI_NOISE } from "@lumera/config";

interface ArbitrationInput {
  runtimeState: RuntimeState;
  corridorEstimate: CorridorEstimate;
  detectedHazards: NormalizedHazard[];
  confidence: ConfidenceState;
  lastGuidanceTimestamps: Map<GuidanceSemanticType, number>; // type -> ms timestamp
  emergencyActive: boolean;
}

// Anti-noise state for direction oscillation prevention
export interface AntiNoiseState {
  lastDirectionMs: number;
  lastDirectionType: GuidanceSemanticType | null;
}

export function arbitrate(
  input: ArbitrationInput,
  antiNoise: AntiNoiseState
): GuidanceDecision | null {
  if (input.emergencyActive) {
    return makeDecision(
      GuidanceSemanticType.ALERT_STOP,
      GuidancePriority.EMERGENCY_STOP,
      input.confidence,
      false,
      0
    );
  }

  // Priority 0: Emergency stop from hazard
  const criticalHazard = input.detectedHazards.find(
    (h) => h.severity === HazardSeverity.CRITICAL && h.distanceM < 2.0
  );
  if (criticalHazard) {
    return makeDecision(
      GuidanceSemanticType.ALERT_STOP,
      GuidancePriority.EMERGENCY_STOP,
      input.confidence,
      false,
      0
    );
  }

  // Priority 1: Hazard avoidance
  const highHazard = input.detectedHazards.find(
    (h) =>
      h.severity === HazardSeverity.HIGH ||
      h.severity === HazardSeverity.CRITICAL
  );
  if (highHazard) {
    const cooldown = getCooldown(
      GuidanceSemanticType.ALERT_HAZARD,
      input.lastGuidanceTimestamps
    );
    if (cooldown === 0) {
      return makeDecision(
        GuidanceSemanticType.ALERT_HAZARD,
        GuidancePriority.HAZARD_AVOIDANCE,
        input.confidence,
        false,
        0
      );
    }
    return makeDecision(
      GuidanceSemanticType.ALERT_HAZARD,
      GuidancePriority.HAZARD_AVOIDANCE,
      input.confidence,
      true,
      cooldown
    );
  }

  // Priority 2: Route correction (only in ACTIVE_RUN or LOW_CONFIDENCE)
  if (
    input.runtimeState === RuntimeState.ACTIVE_RUN ||
    input.runtimeState === RuntimeState.LOW_CONFIDENCE
  ) {
    const correction = computeRouteCorrection(
      input.corridorEstimate,
      input.confidence,
      input.lastGuidanceTimestamps,
      antiNoise
    );
    if (correction) return correction;
  }

  // Priority 3: System low confidence alert
  if (input.confidence.band === ConfidenceBand.CRITICAL) {
    const cooldown = getCooldown(
      GuidanceSemanticType.SYSTEM_LOW_CONFIDENCE,
      input.lastGuidanceTimestamps
    );
    if (cooldown === 0) {
      return makeDecision(
        GuidanceSemanticType.SYSTEM_LOW_CONFIDENCE,
        GuidancePriority.INFORMATIONAL,
        input.confidence,
        false,
        0
      );
    }
  }

  return null;
}

function computeRouteCorrection(
  corridor: CorridorEstimate,
  confidence: ConfidenceState,
  lastTimestamps: Map<GuidanceSemanticType, number>,
  antiNoise: AntiNoiseState
): GuidanceDecision | null {
  const deviation = corridor.deviationFromCenterM;
  const abs = Math.abs(deviation);

  if (abs < CORRIDOR_THRESHOLDS.ON_COURSE_M) return null;

  // Apply hysteresis: only emit if change exceeds threshold
  const isRight = deviation > 0;
  const semanticType =
    abs >= CORRIDOR_THRESHOLDS.STRONG_DRIFT_M
      ? isRight
        ? GuidanceSemanticType.NAV_LEFT_STRONG
        : GuidanceSemanticType.NAV_RIGHT_STRONG
      : isRight
        ? GuidanceSemanticType.NAV_LEFT_SLIGHT
        : GuidanceSemanticType.NAV_RIGHT_SLIGHT;

  const now = Date.now();

  // Anti-oscillation: suppress if same type was very recently emitted
  const directionCooldown =
    antiNoise.lastDirectionType === semanticType
      ? Math.max(0, ANTI_NOISE.DIRECTION_COOLDOWN_MS - (now - antiNoise.lastDirectionMs))
      : 0;

  const cooldown = Math.max(
    directionCooldown,
    getCooldown(semanticType, lastTimestamps)
  );

  return makeDecision(
    semanticType,
    GuidancePriority.ROUTE_CORRECTION,
    confidence,
    cooldown > 0,
    cooldown
  );
}

function getCooldown(
  type: GuidanceSemanticType,
  lastTimestamps: Map<GuidanceSemanticType, number>
): number {
  const last = lastTimestamps.get(type);
  if (!last) return 0;
  const elapsed = Date.now() - last;
  const cooldownMs =
    type === GuidanceSemanticType.ALERT_HAZARD
      ? ANTI_NOISE.HAZARD_COOLDOWN_MS
      : ANTI_NOISE.DIRECTION_COOLDOWN_MS;
  return Math.max(0, cooldownMs - elapsed);
}

function makeDecision(
  semanticType: GuidanceSemanticType,
  priority: GuidancePriority,
  confidence: ConfidenceState,
  suppressedByAntiNoise: boolean,
  cooldownRemainingMs: number
): GuidanceDecision {
  return {
    semanticType,
    priority,
    confidence,
    suppressedByAntiNoise,
    cooldownRemainingMs,
  };
}
