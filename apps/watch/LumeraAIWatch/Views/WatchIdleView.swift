import SwiftUI

struct WatchIdleView: View {
    @EnvironmentObject var runtime: WatchRuntime

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.run")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(runtime.phoneConnected ? .blue : .gray)
                .accessibilityHidden(true)

            Text("LumeraAI")
                .font(.headline)

            Text(runtime.phoneConnected ? "Ready" : "Connect iPhone")
                .font(.caption2)
                .foregroundStyle(runtime.phoneConnected ? .green : .orange)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LumeraAI. Status: \(runtime.phoneConnected ? "Ready" : "Connect iPhone")")
    }
}
