import { RuntimeState } from "./enums.js";

// ─── State Machine Events ─────────────────────────────────────────────────────

export type RuntimeEvent =
  | { type: "BOOT_COMPLETE" }
  | { type: "START_PRE_CHECK" }
  | { type: "PRE_CHECK_PASSED" }
  | { type: "PRE_CHECK_FAILED"; reason: string }
  | { type: "START_RUN" }
  | { type: "CONFIDENCE_DEGRADED" }
  | { type: "CONFIDENCE_CRITICAL" }
  | { type: "CONFIDENCE_RECOVERED" }
  | { type: "SENSOR_FAILURE"; sensor: string }
  | { type: "PAUSE" }
  | { type: "RESUME" }
  | { type: "EMERGENCY_TRIGGER"; source: string }
  | { type: "END_SESSION" }
  | { type: "SYNC_COMPLETE" }
  | { type: "RESET" };

// ─── Transition Table ─────────────────────────────────────────────────────────

export type TransitionMap = {
  [S in RuntimeState]?: {
    [E in RuntimeEvent["type"]]?: RuntimeState;
  };
};

export const TRANSITIONS: TransitionMap = {
  [RuntimeState.BOOT]: {
    BOOT_COMPLETE: RuntimeState.IDLE,
  },
  [RuntimeState.IDLE]: {
    START_PRE_CHECK: RuntimeState.PRE_RUN_CHECK,
    RESET: RuntimeState.IDLE,
  },
  [RuntimeState.PRE_RUN_CHECK]: {
    PRE_CHECK_PASSED: RuntimeState.READY,
    PRE_CHECK_FAILED: RuntimeState.IDLE,
    RESET: RuntimeState.IDLE,
  },
  [RuntimeState.READY]: {
    START_RUN: RuntimeState.ACTIVE_RUN,
    RESET: RuntimeState.IDLE,
  },
  [RuntimeState.ACTIVE_RUN]: {
    CONFIDENCE_DEGRADED: RuntimeState.LOW_CONFIDENCE,
    CONFIDENCE_CRITICAL: RuntimeState.SAFE_MODE,
    PAUSE: RuntimeState.PAUSED,
    EMERGENCY_TRIGGER: RuntimeState.EMERGENCY,
    END_SESSION: RuntimeState.SESSION_COMPLETE,
    SENSOR_FAILURE: RuntimeState.LOW_CONFIDENCE,
  },
  [RuntimeState.LOW_CONFIDENCE]: {
    CONFIDENCE_RECOVERED: RuntimeState.ACTIVE_RUN,
    CONFIDENCE_CRITICAL: RuntimeState.SAFE_MODE,
    PAUSE: RuntimeState.PAUSED,
    EMERGENCY_TRIGGER: RuntimeState.EMERGENCY,
    END_SESSION: RuntimeState.SESSION_COMPLETE,
  },
  [RuntimeState.SAFE_MODE]: {
    CONFIDENCE_RECOVERED: RuntimeState.ACTIVE_RUN,
    PAUSE: RuntimeState.PAUSED,
    EMERGENCY_TRIGGER: RuntimeState.EMERGENCY,
    END_SESSION: RuntimeState.SESSION_COMPLETE,
  },
  [RuntimeState.PAUSED]: {
    RESUME: RuntimeState.ACTIVE_RUN,
    EMERGENCY_TRIGGER: RuntimeState.EMERGENCY,
    END_SESSION: RuntimeState.SESSION_COMPLETE,
    RESET: RuntimeState.IDLE,
  },
  [RuntimeState.EMERGENCY]: {
    END_SESSION: RuntimeState.SESSION_COMPLETE,
    RESET: RuntimeState.IDLE,
  },
  [RuntimeState.SESSION_COMPLETE]: {
    SYNC_COMPLETE: RuntimeState.SYNC_PENDING,
    RESET: RuntimeState.IDLE,
  },
  [RuntimeState.SYNC_PENDING]: {
    SYNC_COMPLETE: RuntimeState.IDLE,
    RESET: RuntimeState.IDLE,
  },
};

// ─── State Machine ────────────────────────────────────────────────────────────

export interface StateMachineContext {
  currentState: RuntimeState;
  previousState: RuntimeState | null;
  enteredAt: Date;
  failureReason?: string;
}

export function transition(
  context: StateMachineContext,
  event: RuntimeEvent
): StateMachineContext {
  const stateTransitions = TRANSITIONS[context.currentState];
  if (!stateTransitions) return context;

  const nextState = stateTransitions[event.type as RuntimeEvent["type"]];
  if (!nextState) return context;

  return {
    currentState: nextState,
    previousState: context.currentState,
    enteredAt: new Date(),
    failureReason:
      event.type === "PRE_CHECK_FAILED" ? event.reason : undefined,
  };
}

export function canTransition(
  current: RuntimeState,
  eventType: RuntimeEvent["type"]
): boolean {
  return TRANSITIONS[current]?.[eventType] !== undefined;
}

export function isActiveSession(state: RuntimeState): boolean {
  return (
    state === RuntimeState.ACTIVE_RUN ||
    state === RuntimeState.LOW_CONFIDENCE ||
    state === RuntimeState.SAFE_MODE ||
    state === RuntimeState.PAUSED
  );
}

export function isSafeToGiveGuidance(state: RuntimeState): boolean {
  return (
    state === RuntimeState.ACTIVE_RUN ||
    state === RuntimeState.LOW_CONFIDENCE
  );
}
