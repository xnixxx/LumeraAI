import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject var runtime: WatchRuntime

    var body: some View {
        if runtime.sessionState == .emergency {
            WatchEmergencyView()
        } else if runtime.sessionState == .paused {
            WatchPausedView()
        } else if runtime.sessionState == .activeRun
                    || runtime.sessionState == .lowConf
                    || runtime.sessionState == .safeMode {
            WatchActiveRunView()
        } else {
            WatchIdleView()
        }
    }
}
