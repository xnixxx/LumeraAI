import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var watchTransport: WatchTransportService
    @State private var showRoutePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.run.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)

                    Text("LumeraAI")
                        .font(.largeTitle.bold())

                    Text("AI Running Guidance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Status indicators
                StatusRow(
                    label: "Apple Watch",
                    isReady: watchTransport.connectionState == .connected,
                    iconName: "applewatch"
                )
                StatusRow(
                    label: "GPS",
                    isReady: appState.locationService.gpsQuality == .good || appState.locationService.gpsQuality == .moderate,
                    iconName: "location.fill"
                )
                StatusRow(
                    label: "Health",
                    isReady: appState.healthKitService.isAuthorized,
                    iconName: "heart.fill"
                )

                Spacer()

                // CTA
                if appState.runtimeState == .ready {
                    Button {
                        showRoutePicker = true
                    } label: {
                        Label("Choose Route & Start", systemImage: "play.circle.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .accessibilityLabel("Choose a route and start running")
                } else {
                    Button {
                        appState.startPreCheck()
                    } label: {
                        Label("Check & Prepare", systemImage: "checkmark.shield.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(appState.runtimeState == .preRunCheck)
                    .accessibilityLabel("Check sensors and prepare for your run")
                }

                NavigationLink("Settings") {
                    SettingsView()
                }
                .font(.footnote)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showRoutePicker) {
                RoutePickerView { route in
                    appState.beginRun(route: route)
                    showRoutePicker = false
                }
            }
        }
    }
}

// MARK: - Status Row

private struct StatusRow: View {
    let label: String
    let isReady: Bool
    let iconName: String

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .frame(width: 24)
                .foregroundStyle(isReady ? .green : .orange)
            Text(label)
                .font(.body)
            Spacer()
            Text(isReady ? "Ready" : "Not Ready")
                .font(.caption)
                .foregroundStyle(isReady ? .green : .orange)
                .bold()
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(isReady ? "Ready" : "Not ready")")
    }
}
