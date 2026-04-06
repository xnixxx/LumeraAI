import {
  RunMode,
  HazardType,
  HazardSeverity,
  ConfidenceBand,
  DeviceConnectionState,
  EmergencyTriggerSource,
  GuidanceSemanticType,
  GuidancePriority,
  SurfaceType,
  RuntimeState,
} from "./enums.js";

// ─── User & Profile ───────────────────────────────────────────────────────────

export interface User {
  id: string;
  name: string;
  email: string;
  accessibilityProfile: AccessibilityProfile;
  signalProfile: SignalProfile;
  createdAt: Date;
}

export interface AccessibilityProfile {
  isBlind: boolean;
  isLowVision: boolean;
  usesVoiceOver: boolean;
  prefersHapticOnly: boolean;
  preferredAudioLanguage: string;
  highContrastEnabled: boolean;
  largeFontEnabled: boolean;
}

export interface SignalProfile {
  hapticIntensity: "low" | "medium" | "high";
  audioVolume: number; // 0.0–1.0
  voiceFeedbackEnabled: boolean;
  metricsAudioInterval: number; // seconds between spoken metrics
  navigationAudioEnabled: boolean;
}

// ─── Route & Segments ─────────────────────────────────────────────────────────

export interface Route {
  id: string;
  name: string;
  description: string;
  environment: RunMode;
  segments: RouteSegment[];
  validationStatus: "pending" | "validated" | "rejected";
  complexityRating: "beginner-safe" | "moderate-complexity" | "advanced-only";
  tags: RouteTag[];
  knownHazardNotes: string[];
  totalDistanceM: number;
  createdBy: string;
  createdAt: Date;
}

export type RouteTag =
  | "beginner-safe"
  | "moderate-complexity"
  | "advanced-only"
  | "daylight-only"
  | "requires-companion"
  | "unsupported-in-poor-weather";

export interface RouteSegment {
  id: string;
  sequenceIndex: number;
  centerPolyline: Coordinate[];
  softCorridorWidthM: number;
  hardCorridorWidthM: number;
  turnPreparationDistanceM: number;
  maxRecommendedSpeedMps: number;
  complexityScore: number; // 0.0–1.0
  surfaceType: SurfaceType;
  knownHazardNotes: string[];
}

export interface Coordinate {
  latitude: number;
  longitude: number;
  altitudeM?: number;
}

// ─── Session ──────────────────────────────────────────────────────────────────

export interface Session {
  id: string;
  userId: string;
  routeId: string;
  runMode: RunMode;
  startedAt: Date;
  endedAt?: Date;
  state: RuntimeState;
  lapCount: number;
  totalDistanceM: number;
  averagePaceMpS: number;
  maxHeartRateBpm?: number;
  averageHeartRateBpm?: number;
  guidanceEvents: GuidanceEvent[];
  hazardEvents: HazardEvent[];
  summaryAudioUrl?: string;
}

// ─── Guidance & Hazard Events ─────────────────────────────────────────────────

export interface GuidanceEvent {
  id: string;
  sessionId: string;
  timestamp: Date;
  semanticType: GuidanceSemanticType;
  priority: GuidancePriority;
  confidenceBand: ConfidenceBand;
  triggerReason: string;
  positionAtEvent?: Coordinate;
}

export interface HazardEvent {
  id: string;
  sessionId: string;
  timestamp: Date;
  hazardType: HazardType;
  severity: HazardSeverity;
  distanceM: number;
  bearing: number; // degrees from runner heading
  resolved: boolean;
  resolvedAt?: Date;
}

// ─── Sensor & Confidence ──────────────────────────────────────────────────────

export interface SensorHealthSnapshot {
  timestamp: Date;
  gpsQuality: "good" | "moderate" | "poor" | "unavailable";
  headingStable: boolean;
  perceptionFps: number;
  imuConsistent: boolean;
  cameraAvailable: boolean;
  cameraOccluded: boolean;
  watchConnected: boolean;
  batteryLevelPercent: number;
}

export interface ConfidenceState {
  band: ConfidenceBand;
  score: number; // 0.0–1.0
  dominantDegradationReason?: string;
  lastUpdated: Date;
}

// ─── Guidance Decision ────────────────────────────────────────────────────────

export interface GuidanceDecision {
  semanticType: GuidanceSemanticType;
  priority: GuidancePriority;
  confidence: ConfidenceState;
  suppressedByAntiNoise: boolean;
  cooldownRemainingMs: number;
}

// ─── Perception ───────────────────────────────────────────────────────────────

export interface PerceptionSnapshot {
  timestamp: Date;
  freeSpaceEstimate: FreeSpaceEstimate;
  detectedHazards: NormalizedHazard[];
  corridorEstimate: CorridorEstimate;
  perceptionConfidence: number; // 0.0–1.0
}

export interface FreeSpaceEstimate {
  availableWidthM: number;
  centerOffsetM: number; // + = right of safe center, - = left
  confidence: number;
}

export interface NormalizedHazard {
  hazardType: HazardType;
  severity: HazardSeverity;
  distanceM: number;
  bearingDeg: number;
  widthM: number;
  confidence: number;
}

export interface CorridorEstimate {
  deviationFromCenterM: number; // + = right, - = left
  onSoftCorridor: boolean;
  onHardCorridor: boolean;
  outsideCorridor: boolean;
  confidence: number;
}

// ─── Watch Transport ──────────────────────────────────────────────────────────

export interface WatchSemanticEvent {
  eventId: string;
  semanticType: GuidanceSemanticType;
  priority: GuidancePriority;
  timestamp: Date;
  durationMs?: number;
  metadata?: Record<string, unknown>;
}

export interface WatchConnectionHealth {
  state: DeviceConnectionState;
  lastHeartbeatAt: Date;
  reconnectAttempts: number;
  rssi?: number;
}

// ─── Emergency ────────────────────────────────────────────────────────────────

export interface EmergencyEvent {
  id: string;
  sessionId: string;
  userId: string;
  triggeredAt: Date;
  triggerSource: EmergencyTriggerSource;
  lastKnownPosition?: Coordinate;
  resolvedAt?: Date;
  checkinAt?: Date;
}
