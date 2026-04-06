import {
  Route,
  Session,
  GuidanceEvent,
  HazardEvent,
  EmergencyEvent,
  User,
  RuntimeState,
} from "@lumera/domain";

// ─── Auth ─────────────────────────────────────────────────────────────────────

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: Pick<User, "id" | "name" | "email">;
}

export interface RefreshRequest {
  refreshToken: string;
}

export interface RefreshResponse {
  accessToken: string;
  expiresIn: number;
}

// ─── Routes ───────────────────────────────────────────────────────────────────

export type RouteListResponse = Pick<
  Route,
  "id" | "name" | "description" | "environment" | "totalDistanceM" | "complexityRating" | "tags" | "validationStatus"
>[];

export type RouteDetailResponse = Route;

export interface CreateRouteRequest {
  name: string;
  description: string;
  environment: Route["environment"];
  segments: Route["segments"];
  tags: Route["tags"];
  knownHazardNotes: string[];
}

export interface ValidateRouteResponse {
  routeId: string;
  validationStatus: Route["validationStatus"];
  issues: string[];
}

// ─── Sessions ─────────────────────────────────────────────────────────────────

export interface StartSessionRequest {
  routeId: string;
  runMode: Session["runMode"];
}

export interface StartSessionResponse {
  sessionId: string;
  startedAt: string;
}

export interface SessionEventsRequest {
  events: Array<GuidanceEvent | HazardEvent>;
}

export interface EndSessionRequest {
  endedAt: string;
  totalDistanceM: number;
  lapCount: number;
  averagePaceMpS: number;
  averageHeartRateBpm?: number;
  maxHeartRateBpm?: number;
  finalState: RuntimeState;
}

export interface EndSessionResponse {
  sessionId: string;
  summaryAvailable: boolean;
}

export type SessionDetailResponse = Session;

export type UserSessionsResponse = Pick<
  Session,
  "id" | "routeId" | "runMode" | "startedAt" | "endedAt" | "totalDistanceM" | "lapCount"
>[];

// ─── Emergency ────────────────────────────────────────────────────────────────

export interface TriggerEmergencyRequest {
  sessionId: string;
  triggerSource: EmergencyEvent["triggerSource"];
  lastKnownLatitude?: number;
  lastKnownLongitude?: number;
}

export interface TriggerEmergencyResponse {
  emergencyId: string;
  triggeredAt: string;
  notificationsSent: boolean;
}

export interface EmergencyCheckinRequest {
  emergencyId: string;
  safeConfirmed: boolean;
}

// ─── Feedback ─────────────────────────────────────────────────────────────────

export interface SessionFeedbackRequest {
  sessionId: string;
  overallRating: 1 | 2 | 3 | 4 | 5;
  guidanceAccuracy: 1 | 2 | 3 | 4 | 5;
  hapticClarity: 1 | 2 | 3 | 4 | 5;
  freeTextComment?: string;
  falseAlertsReported: number;
  missedAlertsReported: number;
}

// ─── Common ───────────────────────────────────────────────────────────────────

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
}
