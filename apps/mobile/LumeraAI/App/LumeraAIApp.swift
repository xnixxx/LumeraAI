import SwiftUI
import WatchConnectivity

@main
struct LumeraAIApp: App {
    @StateObject private var appState = AppStateManager()
    @StateObject private var watchTransport = WatchTransportService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(watchTransport)
                .onAppear {
                    watchTransport.activate()
                }
        }
    }
}
