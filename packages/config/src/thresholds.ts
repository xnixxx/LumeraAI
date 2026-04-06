// Route corridor deviation thresholds (meters)
export const CORRIDOR_THRESHOLDS = {
  ON_COURSE_M: 0.20,
  MILD_DRIFT_M: 0.45,
  STRONG_DRIFT_M: 0.80,
  UNSAFE_M: 0.80,
} as const;

// Confidence score thresholds (0.0–1.0)
export const CONFIDENCE_THRESHOLDS = {
  HIGH_MIN: 0.75,
  MODERATE_MIN: 0.50,
  LOW_MIN: 0.25,
  // below LOW_MIN = CRITICAL
} as const;

// State machine confidence transitions
export const CONFIDENCE_TRANSITION = {
  ACTIVE_TO_LOW_CONFIDENCE: 0.50,
  LOW_CONFIDENCE_TO_SAFE_MODE: 0.25,
  SAFE_MODE_RECOVERY_WINDOW_MS: 5_000,
  RECOVERY_CONFIDENCE_REQUIRED: 0.60,
} as const;

// Anti-noise / guidance smoothing
export const ANTI_NOISE = {
  HYSTERESIS_M: 0.10,           // min change before triggering new correction
  DWELL_TIME_MS: 1_500,         // hold new correction state before emitting
  DIRECTION_COOLDOWN_MS: 2_000, // min ms between same-direction corrections
  HAZARD_COOLDOWN_MS: 3_000,    // min ms between same hazard alerts
} as const;

// Watch connection health
export const WATCH_CONNECTION = {
  HEARTBEAT_INTERVAL_MS: 2_000,
  HEARTBEAT_TIMEOUT_MS: 6_000,
  MAX_RECONNECT_ATTEMPTS: 5,
  RECONNECT_BACKOFF_BASE_MS: 1_000,
} as const;

// GPS quality thresholds
export const GPS_QUALITY = {
  GOOD_ACCURACY_M: 3.0,
  MODERATE_ACCURACY_M: 8.0,
  POOR_ACCURACY_M: 15.0,
} as const;

// Perception freshness
export const PERCEPTION = {
  MIN_ACCEPTABLE_FPS: 5,
  STALE_AFTER_MS: 500,
} as const;

// Battery warnings
export const BATTERY = {
  WARN_PERCENT: 20,
  CRITICAL_PERCENT: 10,
} as const;

// Turn preparation
export const NAVIGATION = {
  TURN_PREP_DISTANCE_M: 10.0,
  TURN_PREP_ALERT_ADVANCE_M: 15.0,
} as const;

// Session
export const SESSION = {
  MAX_PAUSE_BEFORE_END_MS: 30 * 60 * 1_000, // 30 minutes
  SUMMARY_AUDIO_DELAY_MS: 2_000,
} as const;
