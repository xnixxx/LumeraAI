import SwiftUI

struct EmergencyView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var checkinConfirm = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "sos.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Emergency Active")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.red)

                Text("Help is being notified.\nStay where you are.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                checkinConfirm = true
            } label: {
                Label("I Am Safe", systemImage: "checkmark.circle.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityLabel("Confirm I am safe and cancel emergency")
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.red.opacity(0.05).ignoresSafeArea())
        .alert("Confirm Safe?", isPresented: $checkinConfirm) {
            Button("I'm Safe", role: .destructive) {
                Task { await appState.emergencyService.checkin(isSafe: true) }
                appState.endRun()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
