import SwiftUI
import Combine

// MARK: - App State Manager (top-level coordinator)

@MainActor
final class AppStateManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var selectedRoute: RunRoute?
    @Published var runtimeState: RuntimeState = .boot

    let apiClient = APIClient()
    let stateMachine = RunStateMachine()
    let locationService = LocationService()
    let healthKitService = HealthKitService()
    let audioService = AudioCueService()
    let hapticService = HapticService()
    let arbitrationService = GuidanceArbitrationService()

    lazy var sessionLogger = SessionLogger(apiClient: apiClient)
    lazy var emergencyService = EmergencyService(apiClient: apiClient)

    private var cancellables = Set<AnyCancellable>()

    init() {
        bindStateMachine()
    }

    // MARK: - Bindings

    private func bindStateMachine() {
        stateMachine.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.runtimeState = state
                self?.onStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func onStateChange(_ state: RuntimeState) {
        switch state {
        case .lowConfidence:
            audioService.announceConfidenceDegraded()
        case .safeMode:
            audioService.announceSafeMode()
        case .emergency:
            audioService.announceEmergency()
        default:
            break
        }
    }

    // MARK: - Session Lifecycle

    func startPreCheck() {
        stateMachine.send(.startPreCheck)
        Task { await performPreCheck() }
    }

    private func performPreCheck() async {
        await healthKitService.requestAuthorization()
        locationService.requestPermission()
        locationService.startUpdating()

        let gpsOk = locationService.authorizationStatus == .authorizedWhenInUse ||
                    locationService.authorizationStatus == .authorizedAlways
        if gpsOk {
            stateMachine.send(.preCheckPassed)
        } else {
            stateMachine.send(.preCheckFailed(reason: "Location permission denied"))
        }
    }

    func beginRun(route: RunRoute) {
        guard let user = currentUser else { return }
        selectedRoute = route
        stateMachine.send(.startRun)
        Task {
            let sessionId = await sessionLogger.startSession(
                userId: user.id,
                routeId: route.id,
                runMode: route.environment
            )
            emergencyService.configure(sessionId: sessionId)
        }
    }

    func pauseRun() { stateMachine.send(.pause) }
    func resumeRun() { stateMachine.send(.resume) }

    func endRun() {
        Task {
            let session = await sessionLogger.endSession(finalHeartRate: healthKitService.currentHeartRateBpm)
            stateMachine.send(.endSession)
            locationService.stopUpdating()
            healthKitService.stopHeartRateObserver()
            if let session { audioService.announceSessionSummary(session: session) }
        }
    }

    func triggerEmergency(source: EmergencySource = .userSOS) {
        stateMachine.send(.emergencyTrigger(source: source))
        Task { await emergencyService.trigger(source: source) }
    }
}
