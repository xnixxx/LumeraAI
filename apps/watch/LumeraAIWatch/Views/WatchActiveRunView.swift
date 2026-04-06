import SwiftUI

struct WatchActiveRunView: View {
    @EnvironmentObject var runtime: WatchRuntime

    var body: some View {
        VStack(spacing: 6) {
            // State indicator
            stateIndicator

            // Metrics
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LAP")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\(runtime.lapCount)")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("HR")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(runtime.heartRateBpm.map { "\($0)" } ?? "--")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                }
            }
            .padding(.horizontal, 4)

            // Distance
            Text(String(format: "%.2f km", runtime.distanceM / 1000))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            // Controls
            HStack(spacing: 12) {
                Button {
                    runtime.sendPauseCommand()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.blue)
                .clipShape(Circle())
                .accessibilityLabel("Pause run")

                Button {
                    runtime.sendSOSCommand()
                } label: {
                    Image(systemName: "sos")
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.red)
                .clipShape(Circle())
                .accessibilityLabel("Emergency SOS")
            }
        }
        .padding(6)
        .background(stateBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var stateIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: 6, height: 6)
            Text(stateLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(stateColor)
        }
        .accessibilityLabel("State: \(stateLabel)")
    }

    private var stateLabel: String {
        switch runtime.sessionState {
        case .activeRun:  return "Running"
        case .lowConf:    return "Low Confidence"
        case .safeMode:   return "Safe Mode"
        default:          return ""
        }
    }

    private var stateColor: Color {
        switch runtime.sessionState {
        case .activeRun:  return .green
        case .lowConf:    return .yellow
        case .safeMode:   return .orange
        default:          return .gray
        }
    }

    private var stateBackground: Color {
        switch runtime.sessionState {
        case .safeMode:  return Color.orange.opacity(0.12)
        case .lowConf:   return Color.yellow.opacity(0.08)
        default:         return Color.clear
        }
    }
}
