import Foundation
import CoreLocation

// MARK: - Coordinate

struct GeoCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let altitudeM: Double?

    init(_ clLocation: CLLocation) {
        self.latitude = clLocation.coordinate.latitude
        self.longitude = clLocation.coordinate.longitude
        self.altitudeM = clLocation.altitude
    }

    init(latitude: Double, longitude: Double, altitudeM: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeM = altitudeM
    }
}

// MARK: - Route

struct RunRoute: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let environment: RunMode
    let segments: [RouteSegment]
    let totalDistanceM: Double
    let complexityRating: ComplexityRating
    let tags: [RouteTag]
    let knownHazardNotes: [String]
    let validationStatus: ValidationStatus

    enum ComplexityRating: String, Codable {
        case beginnerSafe      = "beginner-safe"
        case moderateComplexity = "moderate-complexity"
        case advancedOnly      = "advanced-only"
    }

    enum ValidationStatus: String, Codable {
        case pending, validated, rejected
    }
}

enum RouteTag: String, Codable {
    case beginnerSafe       = "beginner-safe"
    case moderateComplexity = "moderate-complexity"
    case advancedOnly       = "advanced-only"
    case daylightOnly       = "daylight-only"
    case requiresCompanion  = "requires-companion"
    case unsupportedInPoorWeather = "unsupported-in-poor-weather"
}

enum RunMode: String, Codable {
    case track             = "TRACK"
    case parkLoop          = "PARK_LOOP"
    case predefinedRoute   = "PREDEFINED_ROUTE"
    case intervalTraining  = "INTERVAL_TRAINING"
    case assisted          = "ASSISTED"
}

struct RouteSegment: Identifiable, Codable {
    let id: String
    let sequenceIndex: Int
    let centerPolyline: [GeoCoordinate]
    let softCorridorWidthM: Double
    let hardCorridorWidthM: Double
    let turnPreparationDistanceM: Double
    let maxRecommendedSpeedMps: Double
    let complexityScore: Double
    let surfaceType: SurfaceType
    let knownHazardNotes: [String]
}

enum SurfaceType: String, Codable {
    case trackSynthetic = "TRACK_SYNTHETIC"
    case trackCinder    = "TRACK_CINDER"
    case pathPaved      = "PATH_PAVED"
    case pathGravel     = "PATH_GRAVEL"
    case grass          = "GRASS"
    case mixed          = "MIXED"
    case unknown        = "UNKNOWN"
}

// MARK: - Session

struct RunSession: Identifiable, Codable {
    let id: String
    let userId: String
    let routeId: String
    let runMode: RunMode
    let startedAt: Date
    var endedAt: Date?
    var lapCount: Int
    var totalDistanceM: Double
    var averagePaceMpS: Double
    var maxHeartRateBpm: Int?
    var averageHeartRateBpm: Int?
    var guidanceEvents: [GuidanceEvent]   // var so SessionLogger can update
    var hazardEvents: [HazardEvent]       // var so SessionLogger can update
}

// MARK: - Guidance & Hazard Events

struct GuidanceEvent: Identifiable, Codable {
    let id: String
    let sessionId: String
    let timestamp: Date
    let semanticType: GuidanceSemanticType
    let priority: GuidancePriority
    let triggerReason: String
    let positionAtEvent: GeoCoordinate?
}

enum GuidanceSemanticType: String, Codable {
    case navLeftSlight        = "NAV_LEFT_SLIGHT"
    case navLeftStrong        = "NAV_LEFT_STRONG"
    case navRightSlight       = "NAV_RIGHT_SLIGHT"
    case navRightStrong       = "NAV_RIGHT_STRONG"
    case statusOnRoute        = "STATUS_ON_ROUTE"
    case statusOffRoute       = "STATUS_OFF_ROUTE"
    case alertHazard          = "ALERT_HAZARD"
    case alertSlowDown        = "ALERT_SLOW_DOWN"
    case alertStop            = "ALERT_STOP"
    case trainingLapComplete  = "TRAINING_LAP_COMPLETE"
    case trainingIntervalChange = "TRAINING_INTERVAL_CHANGE"
    case systemLowConfidence  = "SYSTEM_LOW_CONFIDENCE"
    case systemDisconnected   = "SYSTEM_DISCONNECTED"
}

enum GuidancePriority: Int, Codable {
    case emergencyStop    = 0
    case hazardAvoidance  = 1
    case routeCorrection  = 2
    case turnPreparation  = 3
    case trainingCue      = 4
    case informational    = 5
}

struct HazardEvent: Identifiable, Codable {
    let id: String
    let sessionId: String
    let timestamp: Date
    let hazardType: HazardType
    let severity: HazardSeverity
    let distanceM: Double
    let bearing: Double
    var resolved: Bool
    var resolvedAt: Date?
}

enum HazardType: String, Codable {
    case obstacleStatic  = "OBSTACLE_STATIC"
    case obstacleDynamic = "OBSTACLE_DYNAMIC"
    case surfaceHazard   = "SURFACE_HAZARD"
    case laneEdge        = "LANE_EDGE"
    case stepDrop        = "STEP_DROP"
    case surfaceChange   = "SURFACE_CHANGE"
    case unknown         = "UNKNOWN"
}

enum HazardSeverity: String, Codable {
    case low, medium, high, critical
}

// MARK: - Confidence

enum ConfidenceBand: String {
    case high, moderate, low, critical
}

struct ConfidenceState {
    let band: ConfidenceBand
    let score: Double  // 0.0–1.0
    let dominantDegradationReason: String?
    let lastUpdated: Date
}

// MARK: - User Profile

struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    var isBlind: Bool
    var isLowVision: Bool
    var prefersHapticOnly: Bool
    var hapticIntensity: HapticIntensity
    var audioVolume: Double
    var voiceFeedbackEnabled: Bool
    var metricsAudioIntervalSec: Int
    var preferredLanguage: String

    enum HapticIntensity: String, Codable { case low, medium, high }
}
