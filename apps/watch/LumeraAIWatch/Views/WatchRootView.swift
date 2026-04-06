import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject var runtime: WatchRuntime

    var body: some View {
        Group {
            switch runtime.sessionState {
            case .idle:
                WatchIdleView()
            case .activeRun, .lowConf, .safeMode:
                WatchActiveRunView()
            case .paused:
                WatchPausedView()
            case .emergency:
                WatchEmergencyView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: runtime.sessionState)
    }
}
