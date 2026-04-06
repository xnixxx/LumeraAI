import SwiftUI

struct SessionSummaryView: View {
    @EnvironmentObject var appState: AppStateManager

    private var session: RunSession? { appState.sessionLogger.currentSession }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.green)
                        .padding(.top, 24)
                        .accessibilityHidden(true)

                    Text("Run Complete")
                        .font(.largeTitle.bold())

                    // Stats
                    if let session {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            SummaryCard(label: "Distance", value: String(format: "%.2f km", session.totalDistanceM / 1000), icon: "map.fill")
                            SummaryCard(label: "Laps", value: "\(session.lapCount)", icon: "arrow.clockwise")
                            SummaryCard(label: "Avg Pace", value: formattedPace(session.averagePaceMpS), icon: "gauge.medium")
                            if let hr = session.averageHeartRateBpm {
                                SummaryCard(label: "Avg HR", value: "\(hr) bpm", icon: "heart.fill")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Guidance stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Guidance Summary")
                                .font(.headline)
                            HStack {
                                Text("Navigation cues:")
                                Spacer()
                                Text("\(navCueCount(session))")
                                    .bold()
                            }
                            HStack {
                                Text("Hazard alerts:")
                                Spacer()
                                Text("\(hazardCount(session))")
                                    .bold()
                            }
                        }
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 32)

                    Button {
                        appState.stateMachine.send(.reset)
                    } label: {
                        Label("Back to Home", systemImage: "house.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func formattedPace(_ mpS: Double) -> String {
        guard mpS > 0 else { return "--:--" }
        let minPerKm = 1000.0 / (mpS * 60.0)
        let min = Int(minPerKm)
        let sec = Int((minPerKm - Double(min)) * 60)
        return String(format: "%d:%02d /km", min, sec)
    }

    private func navCueCount(_ session: RunSession) -> Int {
        session.guidanceEvents.filter {
            [.navLeftSlight, .navLeftStrong, .navRightSlight, .navRightStrong, .statusOffRoute].contains($0.semanticType)
        }.count
    }

    private func hazardCount(_ session: RunSession) -> Int {
        session.hazardEvents.count
    }
}

private struct SummaryCard: View {
    let label: String
    let value: String
    let icon: String

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
