import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var hapticIntensity: UserProfile.HapticIntensity = .medium
    @State private var audioEnabled = true
    @State private var metricsInterval = 30
    @State private var highContrast = false

    var body: some View {
        Form {
            Section("Accessibility") {
                Toggle("Voice Guidance", isOn: $audioEnabled)
                    .onChange(of: audioEnabled) {
                        appState.audioService.voiceFeedbackEnabled = audioEnabled
                    }
                    .accessibilityLabel("Voice guidance. Toggle to enable or disable spoken cues.")

                Picker("Haptic Intensity", selection: $hapticIntensity) {
                    Text("Low").tag(UserProfile.HapticIntensity.low)
                    Text("Medium").tag(UserProfile.HapticIntensity.medium)
                    Text("High").tag(UserProfile.HapticIntensity.high)
                }
                .accessibilityLabel("Haptic intensity for watch feedback.")

                Toggle("High Contrast Mode", isOn: $highContrast)
                    .accessibilityLabel("High contrast mode. Improves visibility for low-vision users.")
            }

            Section("Audio") {
                Stepper(
                    "Metrics every \(metricsInterval)s",
                    value: $metricsInterval,
                    in: 10...120,
                    step: 10
                )
                .accessibilityLabel("Metrics audio interval: \(metricsInterval) seconds")
            }

            Section("About") {
                LabeledContent("App Version", value: "1.0.0")
                LabeledContent("Build", value: "MVP Track Mode")
                Link("Safety Guidelines", destination: URL(string: "https://lumera.ai/safety")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
