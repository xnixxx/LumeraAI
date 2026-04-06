import SwiftUI
import WatchKit

@main
struct LumeraAIWatchApp: App {
    @StateObject private var watchRuntime = WatchRuntime()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(watchRuntime)
        }
    }
}
