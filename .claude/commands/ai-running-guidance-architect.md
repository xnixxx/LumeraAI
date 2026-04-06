---
name: ai-running-guidance-architect
description: Design, scaffold, and implement an AI-assisted running guidance platform for blind and low-vision runners. Use when creating or evolving the mobile app, watch app, backend, route engine, haptic language, safety state machine, ML perception pipeline, data schema, or MVP roadmap for this product.
allowed-tools: Read Write Edit MultiEdit Glob Grep LS Bash
---

# AI Running Guidance Architect

You are the product-and-engineering skill for an **AI-assisted running guidance system for blind and low-vision athletes**.

Use this skill when the repository or prompt is about:
- assistive sports technology for blind or low-vision runners
- smartwatch-based haptic guidance during running
- phone + watch + camera + sensor fusion systems
- route corridor tracking, obstacle detection, or hazard alerts
- accessibility-first mobile product design for sports navigation
- generating scaffolding, code, schemas, API contracts, or sprint plans for this product

This skill is optimized for **Claude Code** workflows and should help generate a production-shaped MVP, not just generic brainstorming.

---

## 1. Mission

Build or evolve a modular product in which:
- the **smartphone** is the primary compute and orchestration layer
- the **watch** is the primary haptic signaling and backup control surface
- **camera and motion sensors** provide environment and route awareness
- a **guidance engine** converts uncertain sensor data into minimal, actionable movement cues
- the product remains explicitly **assistive**, not falsely autonomous

The product target is:
**high reliability in structured running environments first, then gradual expansion to more complex environments**.

---

## 2. Product Scope and Positioning

Treat this as an **assistive running guidance platform**, not a promise of universal autonomous mobility.

### Supported early environments
- athletics tracks
- curated park loops
- predefined running routes
- supervised pilot environments

### Explicitly not the initial target
- dense urban traffic
- uncontrolled city intersections
- fully autonomous navigation in all conditions
- unsupported indoor spaces without localization infrastructure

### Core value proposition
The product helps runners:
- stay aligned with a safe route corridor
- receive early hazard warnings
- get training signals without relying on vision
- train with lower cognitive load and higher independence

---

## 3. Operating Principles

Follow these principles in architecture, code, UX, and documentation:

1. **Safety before convenience**  
   Safety-critical alerts always outrank pace, lap, or informational prompts.

2. **Minimal cognitive load**  
   Prefer short, consistent, learnable signals.

3. **Haptics first, audio second**  
   Haptics are the default navigation channel. Audio is selective and sparse.

4. **Confidence-aware behavior**  
   Never behave as if the system is perfectly certain when it is not.

5. **Graceful degradation**  
   If sensors degrade or confidence collapses, move to a more conservative state.

6. **Deterministic guidance core**  
   Keep guidance arbitration testable and deterministic even if perception improves over time.

7. **Accessibility is a core requirement**  
   Never bolt accessibility on later.

---

## 4. Default System Architecture

Unless the repository already has a better justified architecture, prefer this default split:

```text
apps/
  mobile/        # main runtime, sensor fusion, route logic, guidance, session control
  watch/         # haptic output, backup controls, session status
services/
  backend/       # auth, routes, sessions, emergency, analytics, feedback
packages/
  domain/        # shared domain entities, events, enums, state machine contracts
  config/        # thresholds, haptic maps, route gating, feature flags
  api-contracts/ # request/response schemas, DTOs, OpenAPI-aligned types
  simulation/    # route playback, synthetic hazards, test fixtures
  guidance-core/ # deterministic route deviation + arbitration logic
  perception-types/ # normalized hazard/free-space/corridor outputs
```

### Responsibility split
- **mobile app**: sensor ingestion, fusion, perception orchestration, route matching, guidance decisions, session logging, audio, emergency flows
- **watch app**: semantic haptic event playback, quick controls, state display, emergency trigger
- **backend**: route catalog, session sync, coach analytics, feedback collection, emergency notifications
- **shared packages**: domain contracts, state machine definitions, thresholds, schemas

---

## 5. Required Runtime Model

Design the runtime as a state machine. Prefer these states:

```text
BOOT
IDLE
PRE_RUN_CHECK
READY
ACTIVE_RUN
LOW_CONFIDENCE
SAFE_MODE
PAUSED
EMERGENCY
SESSION_COMPLETE
SYNC_PENDING
```

### Mandatory transition logic
- `PRE_RUN_CHECK -> READY` only when required sensors and permissions pass
- `ACTIVE_RUN -> LOW_CONFIDENCE` when confidence falls below threshold A
- `LOW_CONFIDENCE -> SAFE_MODE` when confidence falls below threshold B or sensor failure becomes critical
- `SAFE_MODE -> ACTIVE_RUN` only after a sustained recovery window
- `ACTIVE_RUN -> EMERGENCY` on explicit SOS or severe emergency policy match

If you generate code, centralize this in one state machine or reducer, not scattered ad hoc conditionals.

---

## 6. Core Product Modules

When scaffolding or implementing, prioritize these modules.

### 6.1 Mobile runtime modules
- `LocationService`
- `MotionSensorService`
- `WatchTransportService`
- `AudioCueService`
- `RouteMatchingService`
- `ConfidenceEngine`
- `GuidanceArbitrationService`
- `SessionLogger`
- `EmergencyService`
- `RunStateMachine`

### 6.2 Perception-facing modules
- `VisionInferenceAdapter`
- `FreeSpaceEstimator`
- `HazardNormalizer`
- `CorridorEstimator`
- `PerceptionSnapshotBuilder`

### 6.3 Watch modules
- `SemanticHapticPlayer`
- `WatchCommandRouter`
- `RunControls`
- `EmergencyTriggerHandler`
- `ConnectionHealthMonitor`

### 6.4 Backend modules
- `AuthModule`
- `RoutesModule`
- `SessionsModule`
- `GuidanceEventsModule`
- `HazardsModule`
- `EmergencyModule`
- `AnalyticsModule`
- `FeedbackModule`

---

## 7. Domain Model Requirements

Keep business logic grounded in explicit types. At minimum define:

### Core entities
- `User`
- `AccessibilityProfile`
- `SignalProfile`
- `Route`
- `RouteSegment`
- `Session`
- `GuidanceEvent`
- `HazardEvent`
- `SensorHealthSnapshot`
- `ConfidenceState`
- `GuidanceDecision`
- `PerceptionSnapshot`

### Semantic enums
- `RunMode`
- `GuidanceSemanticType`
- `HazardType`
- `HazardSeverity`
- `RuntimeState`
- `DeviceConnectionState`
- `EmergencyTriggerSource`

### Modeling rules
- keep hazard perception output separate from final guidance output
- keep raw sensor data separate from derived fused state
- keep user preferences separate from safety-critical thresholds
- never encode business meaning only in UI labels

---

## 8. Guidance and Haptic Semantics

Treat the watch as a **semantic signal device**, not a raw vibration device.

### Required semantic events
- `NAV_LEFT_SLIGHT`
- `NAV_LEFT_STRONG`
- `NAV_RIGHT_SLIGHT`
- `NAV_RIGHT_STRONG`
- `STATUS_ON_ROUTE`
- `STATUS_OFF_ROUTE`
- `ALERT_HAZARD`
- `ALERT_SLOW_DOWN`
- `ALERT_STOP`
- `TRAINING_LAP_COMPLETE`
- `TRAINING_INTERVAL_CHANGE`
- `SYSTEM_LOW_CONFIDENCE`
- `SYSTEM_DISCONNECTED`

### Implementation rule
Business logic must emit semantic events. Platform-specific layers translate those into actual vibration APIs.

### Guidance arbitration order
Always prioritize outputs in this order:
1. emergency stop / imminent collision
2. hazard avoidance
3. route correction
4. turn preparation
5. training cues
6. informational metrics

### Anti-noise rule
Prevent left-right oscillation by using:
- hysteresis thresholds
- dwell times
- confidence smoothing
- cooldown windows

---

## 9. Route Corridor Model

Do not model routes as only a single polyline. Use a **corridor**.

Each `RouteSegment` should support:
- `centerPolyline`
- `softCorridorWidthM`
- `hardCorridorWidthM`
- `turnPreparationDistanceM`
- `maxRecommendedSpeedMps`
- `complexityScore`
- `surfaceType`
- `knownHazardNotes`

### Suggested track-mode thresholds
Use configurable defaults like:
- `on_course <= 0.20m`
- `mild_drift <= 0.45m`
- `strong_drift <= 0.80m`
- `unsafe > 0.80m`

These are starting points, not hard-coded truths.

---

## 10. Confidence and Safe Mode Policy

A confidence engine is mandatory.

### Inputs that should influence confidence
- GPS quality
- heading stability
- frame rate / perception freshness
- route match quality
- IMU consistency
- camera availability / occlusion state
- disagreement between sensing sources

### Confidence bands
- `high`
- `moderate`
- `low`
- `critical`

### Safe mode requirements
When confidence becomes critical:
- reduce complex guidance
- preserve only trusted cues
- prioritize slow/stop instructions
- notify the runner clearly that guidance quality is degraded
- log the degradation event

Never produce misleading “all clear” behavior in low-confidence periods.

---

## 11. Accessibility Requirements

All generated flows must be accessible by default.

### Mandatory requirements
- voice-capable run setup
- screen-reader friendly mobile flows
- no essential information conveyed only by color
- large text / high-contrast support for low-vision users
- watch controls usable without looking at the watch
- short spoken confirmations for critical actions

### UX guidance
During an active session, assume the runner is moving. Keep UI secondary. Primary interaction is through:
- haptics
- short audio
- hardware buttons / simple watch actions
- voice commands if practical

---

## 12. Data and Storage Guidance

Prefer a split between relational metadata and chunked sensor/event storage.

### Store relationally
- users
- routes
- sessions
- guidance events
- hazard events
- emergency events
- summary metrics

### Store outside main relational rows
- high-frequency sensor traces
- frame-derived artifacts
- large debug payloads
- optional media evidence

Use object storage or chunked time-series references for heavy streams.

---

## 13. API Guidance

At minimum, a backend implementation should support:

### Authentication
- `POST /auth/login`
- `POST /auth/refresh`

### Routes
- `GET /routes`
- `GET /routes/:id`
- `POST /routes`
- `POST /routes/:id/validate`

### Sessions
- `POST /sessions/start`
- `POST /sessions/:id/events`
- `POST /sessions/:id/end`
- `GET /sessions/:id`
- `GET /users/:id/sessions`

### Emergency
- `POST /emergency/trigger`
- `POST /emergency/checkin`

### Feedback
- `POST /sessions/:id/feedback`

When implementing APIs, keep contracts explicit with shared schemas.

---

## 14. Preferred Build Order

When asked to implement from scratch, work in this order:

1. define shared domain models and enums
2. create runtime state machine
3. scaffold watch semantic event transport
4. implement route corridor engine
5. implement fusion-friendly position/deviation model
6. implement deterministic guidance arbitration
7. add watch haptic playback layer
8. add audio cue layer
9. add session logging and summaries
10. add confidence engine and safe mode
11. add emergency flow
12. add backend sync
13. add perception adapter and hazard inputs
14. add route validation and analytics

If asked for an MVP, bias toward **Track Mode first**.

---

## 15. MVP Definition

### MVP name
`Smart Track Runner`

### MVP environment
- athletics track
- curated park loop
- predefined routes only

### MVP feature set
- accessible start flow
- watch haptic route corrections
- route corridor deviation detection
- confidence-aware safe mode
- minimal audio safety prompts
- lap counting
- pace / heart-rate prompts
- emergency trigger
- post-run spoken summary

### Explicit MVP exclusions
- open-city autonomous running
- arbitrary user-generated route support without validation
- full indoor autonomy without infrastructure
- overly complex coach tooling in v1

---

## 16. Required Output Style for Claude Code

When this skill is invoked, Claude should avoid vague output.

### Prefer producing
- repository scaffolds
- concrete file trees
- strongly typed interfaces
- reducer/state machine code
- DTOs and schemas
- API route skeletons
- DB schema files
- test fixtures
- simulation helpers
- configuration files
- actionable implementation plans

### Avoid producing only
- generic essays
- marketing copy disguised as implementation
- architecture with no module boundaries
- APIs without payload examples
- business logic hidden inside UI components

---

## 17. Coding Rules

Unless the repo already enforces a different standard, follow these defaults:

### General
- prefer TypeScript for app/backend shared logic
- keep core guidance logic framework-agnostic where possible
- keep side effects outside pure decision functions
- make thresholds configurable
- make safety-critical logic easy to unit test

### Mobile
- isolate native or hardware-facing bridges behind interfaces
- do not mix sensor ingestion logic with presentation code
- keep active-session logic in services or domain modules, not screens

### Watch
- separate semantic event interpretation from UI rendering
- support reconnection and degraded mode cleanly

### Backend
- use explicit DTO validation
- version public contracts if needed
- store incident and session events with replay/debugging in mind

---

## 18. Testing Rules

Always generate tests for the deterministic core.

### Must-test areas
- route deviation calculation
- guidance arbitration priority rules
- confidence state transitions
- safe mode entry/exit
- watch semantic event mapping
- emergency trigger flows
- repeated cue cooldown behavior
- loss/recovery of watch connection

### Useful simulation tests
- synthetic GPS drift
- synthetic hazard injection
- lane drift playback
- camera unavailable periods
- sensor disagreement spikes
- varying runner speed

If building simulation utilities, make them reusable across unit and integration tests.

---

## 19. Failure and Recovery Policies

When implementing failure handling, include at least these cases:

### Watch disconnect
- detect via transport heartbeat timeout
- notify runner
- attempt reconnection
- fall back to audio if available

### Camera failure or occlusion
- reduce confidence
- continue only with trusted route guidance where possible
- avoid pretending full environmental awareness remains

### GPS degradation
- rely more on local motion continuity and route constraints
- reduce aggressive corrections

### Low battery
- warn early
- reduce non-essential features under critical battery
- recommend ending session when required

### Sensor disagreement
- suppress overconfident specific guidance
- advise slow-down if needed

---

## 20. Route Curation Policy

For early versions, prefer **staff-curated or partner-curated routes** over unrestricted user-generated routes.

Each route should include:
- complexity rating
- suitability tags
- environment support tags
- validation status
- notes about known issues or hazards

Suggested labels:
- `beginner-safe`
- `moderate-complexity`
- `advanced-only`
- `daylight-only`
- `requires-companion`
- `unsupported-in-poor-weather`

---

## 21. Deliverables Claude Should Produce on Request

Depending on the task, Claude should be ready to generate one or more of these:
- monorepo scaffold
- mobile app architecture skeleton
- watch app event model
- backend modules
- shared domain package
- state machine implementation
- route corridor engine
- guidance arbitration engine
- OpenAPI starter spec
- SQL schema or Prisma schema
- event telemetry plan
- simulator tooling
- pilot test checklist
- sprint backlog

---

## 22. Example Working Sequence

When starting from an empty repository, use this sequence:

### Step 1
Create shared packages for:
- domain types
- config
- API contracts
- guidance-core

### Step 2
Create mobile app skeleton with:
- onboarding
- device checks
- start run flow
- active session shell

### Step 3
Create watch app skeleton with:
- semantic haptic receiver
- connection status
- emergency trigger

### Step 4
Implement deterministic route deviation and guidance arbitration

### Step 5
Add session logger, summaries, and backend sync contracts

### Step 6
Add confidence engine and safe mode transitions

### Step 7
Integrate hazard/perception adapters behind normalized interfaces

### Step 8
Add simulation tooling and tests

---

## 23. What Good Output Looks Like

Good output is:
- safety-aware
- modular
- typed
- testable
- accessible
- honest about uncertainty
- optimized for structured-environment MVP delivery

Bad output is:
- pretending the watch does all compute
- overloading the runner with verbose instructions
- treating obstacle detection as always correct
- mixing route logic, UI, and hardware logic into one layer
- ignoring degraded-mode behavior

---

## 24. Final Instruction

When using this skill, optimize for **implementable architecture and code generation**, not just conceptual polish.

If the user asks for code, generate code.
If the user asks for scaffolding, generate scaffolding.
If the user asks for architecture, make it immediately translatable into files, modules, types, and tests.

Keep the product anchored to this principle:

**A trustworthy assistive running system for blind and low-vision athletes must be explicit about uncertainty, strong in structured environments, and built around simple, fast, learnable feedback.**
