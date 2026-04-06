import SwiftUI

struct RoutePickerView: View {
    let onSelect: (RunRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var routes: [RunRoute] = RoutePickerView.sampleRoutes()

    var body: some View {
        NavigationStack {
            List(routes) { route in
                Button {
                    onSelect(route)
                } label: {
                    RouteRow(route: route)
                }
                .accessibilityLabel("\(route.name). \(route.description). Complexity: \(route.complexityRating.rawValue). Distance: \(String(format: "%.1f", route.totalDistanceM / 1000)) kilometres.")
            }
            .navigationTitle("Choose Route")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // Sample routes for MVP
    static func sampleRoutes() -> [RunRoute] {
        [
            RunRoute(
                id: "track-400",
                name: "Standard 400m Track",
                description: "Athletics track, flat surface, controlled environment.",
                environment: .track,
                segments: [],
                totalDistanceM: 400,
                complexityRating: .beginnerSafe,
                tags: [.beginnerSafe],
                knownHazardNotes: [],
                validationStatus: .validated
            ),
            RunRoute(
                id: "park-loop-2k",
                name: "Park Loop 2km",
                description: "Paved park path, moderate complexity.",
                environment: .parkLoop,
                segments: [],
                totalDistanceM: 2000,
                complexityRating: .moderateComplexity,
                tags: [.moderateComplexity, .daylightOnly],
                knownHazardNotes: ["Slight incline at 800m"],
                validationStatus: .validated
            ),
        ]
    }
}

private struct RouteRow: View {
    let route: RunRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(route.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f km", route.totalDistanceM / 1000))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(route.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ComplexityBadge(rating: route.complexityRating)
                if route.validationStatus == .validated {
                    Label("Validated", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ComplexityBadge: View {
    let rating: RunRoute.ComplexityRating

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch rating {
        case .beginnerSafe:      return "Beginner"
        case .moderateComplexity: return "Moderate"
        case .advancedOnly:      return "Advanced"
        }
    }

    private var color: Color {
        switch rating {
        case .beginnerSafe:      return .green
        case .moderateComplexity: return .orange
        case .advancedOnly:      return .red
        }
    }
}
