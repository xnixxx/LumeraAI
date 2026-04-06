export interface FeatureFlags {
  enableCameraPerception: boolean;
  enableVoiceCommands: boolean;
  enableCoachAnalytics: boolean;
  enableEmergencyAutoTrigger: boolean;
  enableHeartRateGuidance: boolean;
  enableBackendSync: boolean;
  enableSimulationMode: boolean;
  enableDebugOverlay: boolean;
}

export const DEFAULT_FEATURE_FLAGS: FeatureFlags = {
  enableCameraPerception: true,
  enableVoiceCommands: false,       // Phase 2
  enableCoachAnalytics: true,
  enableEmergencyAutoTrigger: true,
  enableHeartRateGuidance: true,
  enableBackendSync: true,
  enableSimulationMode: false,
  enableDebugOverlay: false,
};
