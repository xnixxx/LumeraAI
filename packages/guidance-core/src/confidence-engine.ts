import {
  ConfidenceBand,
  ConfidenceState,
  SensorHealthSnapshot,
} from "@lumera/domain";
import { CONFIDENCE_THRESHOLDS, GPS_QUALITY, PERCEPTION } from "@lumera/config";

interface ConfidenceInputs {
  sensorHealth: SensorHealthSnapshot;
  routeMatchQuality: number;    // 0.0–1.0
  perceptionFreshness: number;  // 0.0–1.0 (1 = fresh)
  sensorAgreementScore: number; // 0.0–1.0 (1 = perfect agreement)
}

export function computeConfidenceScore(inputs: ConfidenceInputs): number {
  const gpsScore = gpsQualityScore(inputs.sensorHealth);
  const headingScore = inputs.sensorHealth.headingStable ? 1.0 : 0.4;
  const fpsScore =
    inputs.sensorHealth.perceptionFps >= PERCEPTION.MIN_ACCEPTABLE_FPS
      ? Math.min(inputs.sensorHealth.perceptionFps / 15, 1.0)
      : 0.2;
  const cameraScore = inputs.sensorHealth.cameraAvailable
    ? inputs.sensorHealth.cameraOccluded
      ? 0.3
      : 1.0
    : 0.0;
  const imuScore = inputs.sensorHealth.imuConsistent ? 1.0 : 0.4;
  const watchScore = inputs.sensorHealth.watchConnected ? 1.0 : 0.6;

  // Weighted combination
  const score =
    gpsScore * 0.30 +
    headingScore * 0.15 +
    fpsScore * 0.10 +
    cameraScore * 0.10 +
    imuScore * 0.10 +
    inputs.routeMatchQuality * 0.10 +
    inputs.perceptionFreshness * 0.10 +
    inputs.sensorAgreementScore * 0.10 +
    watchScore * 0.05;

  return Math.max(0, Math.min(1, score));
}

function gpsQualityScore(health: SensorHealthSnapshot): number {
  switch (health.gpsQuality) {
    case "good":
      return 1.0;
    case "moderate":
      return 0.65;
    case "poor":
      return 0.3;
    case "unavailable":
      return 0.0;
  }
}

export function scoreToBand(score: number): ConfidenceBand {
  if (score >= CONFIDENCE_THRESHOLDS.HIGH_MIN) return ConfidenceBand.HIGH;
  if (score >= CONFIDENCE_THRESHOLDS.MODERATE_MIN) return ConfidenceBand.MODERATE;
  if (score >= CONFIDENCE_THRESHOLDS.LOW_MIN) return ConfidenceBand.LOW;
  return ConfidenceBand.CRITICAL;
}

export function buildConfidenceState(
  inputs: ConfidenceInputs
): ConfidenceState {
  const score = computeConfidenceScore(inputs);
  const band = scoreToBand(score);
  const reason = identifyDominantDegradation(inputs, score);
  const base: ConfidenceState = { band, score, lastUpdated: new Date() };
  return reason !== undefined
    ? { ...base, dominantDegradationReason: reason }
    : base;
}

function identifyDominantDegradation(
  inputs: ConfidenceInputs,
  _score: number
): string | undefined {
  const { sensorHealth } = inputs;
  if (sensorHealth.gpsQuality === "unavailable") return "gps_unavailable";
  if (sensorHealth.gpsQuality === "poor") return "gps_poor";
  if (!sensorHealth.imuConsistent) return "imu_inconsistent";
  if (!sensorHealth.cameraAvailable) return "camera_unavailable";
  if (sensorHealth.cameraOccluded) return "camera_occluded";
  if (!sensorHealth.headingStable) return "heading_unstable";
  if (inputs.routeMatchQuality < 0.3) return "route_match_poor";
  if (inputs.sensorAgreementScore < 0.3) return "sensor_disagreement";
  return undefined;
}
