import SwiftUI

struct MathsView: View {
    var body: some View {
        List {
            Section("How the maths works") {
                Text("The guide bush rides against the template edge while the cutter spins inside it, so the cut line is offset from the template edge. Only two formulas exist:")
                Label("Offset = (Bush − Cutter) / 2 — when the piece you keep is on the same side as the bush (female→hole, male→plug).", systemImage: "1.circle")
                Label("Offset = (Bush + Cutter) / 2 — when the cutter works beyond the bush footprint (female→plug, male→hole).", systemImage: "2.circle")
            }
            Section("Corners") {
                Text("A round cutter can't cut a sharp internal corner — the minimum internal corner radius equals the cutter radius. Likewise the round bush can't follow template corners tighter than the bush radius, so give your templates corner radii of at least half the bush diameter.")
            }
            Section("Depth of cut") {
                Text("Rule of thumb — don't take more than about half the cutter diameter per pass in hardwood (a full diameter in soft material with a sharp cutter). The calculator suggests a pass count when you enter a cut depth.")
            }
            Section("Worked example") {
                Text("A 60 mm circular template with an 8 mm offset pair.")
                Text("Hole: 8 mm cutter + 24 mm bush → (24−8)/2 = 8 → hole Ø = 60 − 2×8 = 44 mm.")
                Text("Plug: 6 mm cutter + 10 mm bush → (10+6)/2 = 8 → plug Ø = 60 − 2×8 = 44 mm.")
                Text("A perfect-fit inlay.").bold()
            }
            Section {
                Text("Interactive adaptation of “Router Offset Tables” © Peter Parfitt 2026.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("The Maths")
    }
}
