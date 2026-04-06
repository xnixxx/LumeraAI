import SwiftUI

struct WatchEmergencyView: View {
    @EnvironmentObject var runtime: WatchRuntime

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sos.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text("Emergency")
                .font(.headline)
                .foregroundStyle(.red)

            Text("Help notified")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                runtime.sendCommand_safe()
            } label: {
                Text("I'm Safe")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .accessibilityLabel("Confirm I am safe")
        }
        .padding(4)
    }
}

// WatchRuntime extension for safe checkin command
extension WatchRuntime {
    func sendCommand_safe() {
        sendCommand("SAFE_CHECKIN")
    }
}
