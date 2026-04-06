import { GuidanceSemanticType } from "@lumera/domain";

// Haptic pattern descriptor — platform layers translate these to native APIs
export interface HapticPattern {
  pulses: HapticPulse[];
  repeatCount: number;
}

export interface HapticPulse {
  intensityNormalized: number; // 0.0–1.0
  durationMs: number;
  pauseAfterMs: number;
}

// Semantic haptic map
// Patterns are described semantically; the watch layer translates to WKHapticType
export const HAPTIC_MAP: Record<GuidanceSemanticType, HapticPattern> = {
  [GuidanceSemanticType.NAV_LEFT_SLIGHT]: {
    pulses: [{ intensityNormalized: 0.5, durationMs: 80, pauseAfterMs: 0 }],
    repeatCount: 1,
  },
  [GuidanceSemanticType.NAV_LEFT_STRONG]: {
    pulses: [
      { intensityNormalized: 0.9, durationMs: 120, pauseAfterMs: 80 },
      { intensityNormalized: 0.9, durationMs: 120, pauseAfterMs: 0 },
    ],
    repeatCount: 1,
  },
  [GuidanceSemanticType.NAV_RIGHT_SLIGHT]: {
    pulses: [{ intensityNormalized: 0.5, durationMs: 80, pauseAfterMs: 0 }],
    repeatCount: 1,
  },
  [GuidanceSemanticType.NAV_RIGHT_STRONG]: {
    pulses: [
      { intensityNormalized: 0.9, durationMs: 120, pauseAfterMs: 80 },
      { intensityNormalized: 0.9, durationMs: 120, pauseAfterMs: 0 },
    ],
    repeatCount: 1,
  },
  [GuidanceSemanticType.STATUS_ON_ROUTE]: {
    pulses: [{ intensityNormalized: 0.4, durationMs: 60, pauseAfterMs: 0 }],
    repeatCount: 1,
  },
  [GuidanceSemanticType.STATUS_OFF_ROUTE]: {
    pulses: [
      { intensityNormalized: 0.8, durationMs: 200, pauseAfterMs: 100 },
      { intensityNormalized: 0.8, durationMs: 200, pauseAfterMs: 0 },
    ],
    repeatCount: 2,
  },
  [GuidanceSemanticType.ALERT_HAZARD]: {
    pulses: [
      { intensityNormalized: 1.0, durationMs: 100, pauseAfterMs: 60 },
      { intensityNormalized: 1.0, durationMs: 100, pauseAfterMs: 60 },
      { intensityNormalized: 1.0, durationMs: 100, pauseAfterMs: 0 },
    ],
    repeatCount: 1,
  },
  [GuidanceSemanticType.ALERT_SLOW_DOWN]: {
    pulses: [
      { intensityNormalized: 0.9, durationMs: 150, pauseAfterMs: 100 },
      { intensityNormalized: 0.7, durationMs: 150, pauseAfterMs: 0 },
    ],
    repeatCount: 1,
  },
  [GuidanceSemanticType.ALERT_STOP]: {
    pulses: [
      { intensityNormalized: 1.0, durationMs: 400, pauseAfterMs: 0 },
    ],
    repeatCount: 3,
  },
  [GuidanceSemanticType.TRAINING_LAP_COMPLETE]: {
    pulses: [
      { intensityNormalized: 0.6, durationMs: 80, pauseAfterMs: 60 },
      { intensityNormalized: 0.6, durationMs: 80, pauseAfterMs: 60 },
      { intensityNormalized: 0.8, durationMs: 120, pauseAfterMs: 0 },
    ],
    repeatCount: 1,
  },
  [GuidanceSemanticType.TRAINING_INTERVAL_CHANGE]: {
    pulses: [
      { intensityNormalized: 0.7, durationMs: 100, pauseAfterMs: 80 },
      { intensityNormalized: 0.7, durationMs: 100, pauseAfterMs: 0 },
    ],
    repeatCount: 1,
  },
  [GuidanceSemanticType.SYSTEM_LOW_CONFIDENCE]: {
    pulses: [
      { intensityNormalized: 0.5, durationMs: 300, pauseAfterMs: 200 },
    ],
    repeatCount: 2,
  },
  [GuidanceSemanticType.SYSTEM_DISCONNECTED]: {
    pulses: [
      { intensityNormalized: 0.6, durationMs: 200, pauseAfterMs: 150 },
      { intensityNormalized: 0.6, durationMs: 200, pauseAfterMs: 0 },
    ],
    repeatCount: 3,
  },
};
