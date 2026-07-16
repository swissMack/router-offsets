import SwiftUI

struct TablesView: View {
    @Environment(CalculatorState.self) private var state
    @AppStorage("highlightInlay") private var highlight = true

    private let tableOrder: [Scenario] = [.femHole, .femPlug, .maleHole, .malePlug]

    var body: some View {
        List {
            Section {
                Toggle("Highlight inlay pairs (8 / 9 / 10 mm) in female tables", isOn: $highlight)
            }
            ForEach(tableOrder) { scenario in
                Section(scenario.tableTitle) {
                    Text(scenario.tableCaption)
                        .font(.footnote).foregroundStyle(.secondary)
                    table(for: scenario)
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Offset Tables")
    }

    @ViewBuilder
    private func table(for scenario: Scenario) -> some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            GridRow {
                cellText("B\\C", bold: true)
                ForEach(Offsets.cutters, id: \.self) { c in cellText(Offsets.fmt(c), bold: true) }
            }
            ForEach(Offsets.bushes, id: \.self) { b in
                GridRow {
                    cellText(Offsets.fmt(b), bold: true, bg: Color(hex: "dff0f5"))
                    ForEach(Offsets.cutters, id: \.self) { c in
                        cell(scenario, b, c)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ scenario: Scenario, _ b: Double, _ c: Double) -> some View {
        let impossible = Offsets.impossible(bush: b, cutter: c)
        let o = Offsets.offset(scenario, bush: b, cutter: c)
        let bg = cellColor(scenario, o, impossible: impossible)
        Button {
            guard !impossible else { return }
            state.load(scenario: scenario, bush: b, cutter: c)
            state.selectedTab = 0
        } label: {
            cellText(impossible ? "—" : Offsets.fmt(o), bg: bg)
        }
        .buttonStyle(.plain)
        .disabled(impossible)
    }

    private func cellColor(_ scenario: Scenario, _ o: Double, impossible: Bool) -> Color {
        if impossible { return Color(hex: "c9c9c9") }
        let female = (scenario == .femHole || scenario == .femPlug)
        if highlight && female {
            switch o {
            case 8:  return Color(hex: "aecdf7")
            case 9:  return Color(hex: "f5c9a2")
            case 10: return Color(hex: "cbb3ec")
            default: break
            }
        }
        return Color(.secondarySystemGroupedBackground)
    }

    private func cellText(_ s: String, bold: Bool = false, bg: Color = Color(.secondarySystemGroupedBackground)) -> some View {
        Text(s)
            .font(.caption.weight(bold ? .semibold : .regular))
            .frame(maxWidth: .infinity, minHeight: 28)
            .background(bg)
            .foregroundStyle(.primary)
    }
}

extension Scenario {
    var tableTitle: String {
        switch self {
        case .femHole:  return "Female template → HOLE"
        case .femPlug:  return "Female template → PLUG"
        case .maleHole: return "Male template → HOLE"
        case .malePlug: return "Male template → PLUG"
        }
    }
    var tableCaption: String {
        switch self {
        case .femHole:  return "Hole SMALLER · offset = (B−C)/2 · Hole Ø = Template − 2×offset"
        case .femPlug:  return "Plug SMALLER · offset = (B+C)/2 · Plug Ø = Template − 2×offset"
        case .maleHole: return "Hole BIGGER · offset = (B+C)/2 · Hole Ø = Template + 2×offset"
        case .malePlug: return "Plug BIGGER · offset = (B−C)/2 · Plug Ø = Template + 2×offset"
        }
    }
}
