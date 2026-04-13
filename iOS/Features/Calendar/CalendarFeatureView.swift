import SwiftUI

struct CalendarFeatureView: View {
    private let sampleEvents: [(String, String)] = [
        ("Design Review", "10:00 AM"),
        ("Sync", "2:00 PM"),
        ("Focus Block", "4:00 PM"),
    ]

    var body: some View {
        NavigationStack {
            List(sampleEvents, id: \.0) { event in
                VStack(alignment: .leading) {
                    Text(event.0)
                        .font(.headline)
                    Text(event.1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Calendar")
        }
    }
}
