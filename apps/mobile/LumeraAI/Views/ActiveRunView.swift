import SwiftUI

struct ActiveRunView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var showEndConfirm = false

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // State banner
                stateBanner

                // Metrics grid
                metricsGrid
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Confidence indicator
                confidenceBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                // Controls
                controlBar
                    .padding(.bottom, 32)
            }
        }
        .accessibilityElement(children: .contain)
        .alert("End Run?", isPresented: $showEndConfirm) {
            Button("End Run", role: .destructive) { appState.endRun() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your session will be saved and a summary will be read aloud.")
        }
    }

    // MARK: - State Banner

    private var stateBanner: some View {
        HStack {
            Image(systemName: stateIcon)
            Text(stateLabel)
                .font(.headline)
        }
        .foregroundStyle(stateColor)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(stateColor.opacity(0.15))
        .accessibilityLabel("Run state: \(stateLabel)")
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCard(
                label: "Pace",
                value: formattedPace,
                icon: "gauge.medium",
                accessibilityLabel: "Pace: \(formattedPace) per kilometre"
            )
            MetricCard(
                label: "Distance",
                value: formattedDistance,
                icon: "map",
                accessibilityLabel: "Distance: \(formattedDistance)"
            )
            MetricCard(
                label: "Heart Rate",
                value: formattedHeartRate,
                icon: "heart.fill",
                accessibilityLabel: "Heart rate: \(formattedHeartRate)"
            )
            MetricCard(
                label: "Lap",
                value: "\(appState.sessionLogger.currentSession?.lapCount ?? 0)",
                icon: "arrow.clockwise",
                accessibilityLabel: "Lap number: \(appState.sessionLogger.currentSession?.lapCount ?? 0)"
            )
        }
    }

    // MARK: - Confidence Bar

    private var confidenceBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Guidance Confidence")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: confidenceScore, total: 1.0)
                .tint(confidenceColor)
                .scaleEffect(y: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Guidance confidence: \(Int(confidenceScore * 100)) percent")
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 24) {
            // Emergency SOS
            Button {
                appState.triggerEmergency(source: .userSOS)
            } label: {
                Image(systemName: "sos.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.red)
            }
            .accessibilityLabel("Emergency SOS")

            // Pause / Resume
            Button {
                if appState.runtimeState == .paused { appState.resumeRun() }
                else { appState.pauseRun() }
            } label: {
                Image(systemName: appState.runtimeState == .paused ? "play.circle.fill" : "pause.circle.fill")
                    .resizable()
                    .frame(width: 72, height: 72)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(appState.runtimeState == .paused ? "Resume run" : "Pause run")

            // End run
            Button {
                showEndConfirm = true
            } label: {
                Image(systemName: "stop.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.orange)
            }
            .accessibilityLabel("End run")
        }
    }

    // MARK: - Computed

    private var backgroundColor: Color {
        switch appState.runtimeState {
        case .safeMode:      return Color.orange.opacity(0.08)
        case .lowConfidence: return Color.yellow.opacity(0.06)
        case .paused:        return Color.gray.opacity(0.08)
        default:             return Color(.systemBackground)
        }
    }

    private var stateIcon: String {
        switch appState.runtimeState {
        case .activeRun:     return "figure.run"
        case .lowConfidence: return "exclamationmark.triangle.fill"
        case .safeMode:      return "shield.lefthalf.filled"
        case .paused:        return "pause.fill"
        default:             return "circle"
        }
    }

    private var stateLabel: String {
        switch appState.runtimeState {
        case .activeRun:     return "Running"
        case .lowConfidence: return "Low Confidence"
        case .safeMode:      return "Safe Mode — Slow Down"
        case .paused:        return "Paused"
        default:             return ""
        }
    }

    private var stateColor: Color {
        switch appState.runtimeState {
        case .activeRun:     return .green
        case .lowConfidence: return .yellow
        case .safeMode:      return .orange
        case .paused:        return .gray
        default:             return .primary
        }
    }

    private var confidenceScore: Double {
        // Placeholder — connected to GuidanceArbitrationService in production
        switch appState.runtimeState {
        case .activeRun:     return 0.85
        case .lowConfidence: return 0.45
        case .safeMode:      return 0.20
        default:             return 0.5
        }
    }

    private var confidenceColor: Color {
        if confidenceScore >= 0.75 { return .green }
        if confidenceScore >= 0.50 { return .yellow }
        if confidenceScore >= 0.25 { return .orange }
        return .red
    }

    private var formattedPace: String {
        let pace = appState.sessionLogger.currentSession?.averagePaceMpS ?? 0
        guard pace > 0 else { return "--:--" }
        let minPerKm = 1000.0 / (pace * 60.0)
        let min = Int(minPerKm)
        let sec = Int((minPerKm - Double(min)) * 60)
        return String(format: "%d:%02d /km", min, sec)
    }

    private var formattedDistance: String {
        let d = appState.sessionLogger.currentSession?.totalDistanceM ?? 0
        return String(format: "%.2f km", d / 1000)
    }

    private var formattedHeartRate: String {
        if let bpm = appState.healthKitService.currentHeartRateBpm { return "\(bpm) bpm" }
        return "-- bpm"
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let label: String
    let value: String
    let icon: String
    let accessibilityLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.monospacedDigit().bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}
