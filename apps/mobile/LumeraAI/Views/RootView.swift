import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        Group {
            switch appState.runtimeState {
            case .boot, .idle, .preRunCheck, .ready:
                HomeView()
            case .activeRun, .lowConfidence, .safeMode, .paused:
                ActiveRunView()
            case .emergency:
                EmergencyView()
            case .sessionComplete, .syncPending:
                SessionSummaryView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.runtimeState)
    }
}
