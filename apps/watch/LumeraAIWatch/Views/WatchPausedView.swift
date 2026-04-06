import SwiftUI

struct WatchPausedView: View {
    @EnvironmentObject var runtime: WatchRuntime

    var body: some View {
        VStack(spacing: 12) {
            Text("Paused")
                .font(.headline)
                .foregroundStyle(.orange)

            HStack(spacing: 12) {
                Button {
                    runtime.sendResumeCommand()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .accessibilityLabel("Resume run")

                Button {
                    runtime.sendEndSessionCommand()
                } label: {
                    Label("End", systemImage: "stop.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .accessibilityLabel("End run")
            }
        }
    }
}
