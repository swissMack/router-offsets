import SwiftUI

struct TablesView: View {
    @Environment(CalculatorState.self) private var state
    @Environment(AppModel.self) private var appModel
    @AppStorage("highlightInlay") private var highlight = true

    private let tableOrder: [Scenario] = [.femHole, .femPlug, .maleHole, .malePlug]

    private static let rankColors: [Color] = [
        Color(hex: "aecdf7"), Color(hex: "f5c9a2"), Color(hex: "cbb3ec")
    ]

    var body: some View {
        @Bindable var appModel = appModel
        List {
            Section {
                Picker("Units", selection: $appModel.tableUnit) {
                    Text("Metric chart").tag(UnitSystem.metric)
                    Text("Imperial chart").tag(UnitSystem.imperial)
                }
                .pickerStyle(.segmented)
                Toggle("Highlight inlay offset pairs in the two female-template tables", isOn: $highlight)
                legend
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

    private var tops: [Double] { topPairs(appModel.tableUnit) }

    @ViewBuilder
    private var legend: some View {
        let unit = appModel.tableUnit
        VStack(alignment: .leading, spacing: 4) {
            legendChip(color: Color(hex: "c9c9c9"), text: "Impossible — cutter too large for the guide bush")
            ForEach(Array(tops.enumerated()), id: \.offset) { i, t in
                let label = unit == .metric ? "\(fmtN(t)) mm" : fracIn(t)
                legendChip(color: Self.rankColors[i], text: "\(label) inlay pair")
            }
            if appModel.kitActive(.bush) || appModel.kitActive(.cutter) {
                legendChip(color: Color.white.opacity(0.35), text: "Dimmed = not in my kit")
            }
        }
        .font(.caption)
    }

    private func legendChip(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(text)
        }
    }

    @ViewBuilder
    private func table(for scenario: Scenario) -> some View {
        let unit = appModel.tableUnit
        let idx = unit == .metric ? 0 : 1
        let bs = Catalog.bushes[idx]
        let cs = Catalog.cutters[idx]
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            GridRow {
                cellText("B\\C", bold: true)
                ForEach(cs) { c in cellText(c.label, bold: true) }
            }
            ForEach(bs) { b in
                GridRow {
                    cellText(b.label, bold: true, bg: Color(hex: "dff0f5"))
                    ForEach(cs) { c in
                        cell(scenario, b, c, unit: unit)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ scenario: Scenario, _ b: Size, _ c: Size, unit: UnitSystem) -> some View {
        let impossible = Offsets.impossible(bush: b.mm, cutter: c.mm)
        let o = Offsets.offset(scenario, bush: b.mm, cutter: c.mm)
        let bg = cellColor(scenario, o, impossible: impossible)
        let disp = unit == .metric ? fmtN(o) : fracIn(o).replacingOccurrences(of: "″", with: "")
        let dimmed = (appModel.kitActive(.bush) && !appModel.kit.contains(b.id))
            || (appModel.kitActive(.cutter) && !appModel.kit.contains(c.id))
        Button {
            guard !impossible else { return }
            state.bushChoice = .standard(id: b.id)
            state.cutterChoice = .standard(id: c.id)
            state.scenario = scenario
            state.selectedTab = 0
        } label: {
            cellText(impossible ? "—" : disp, bg: bg)
        }
        .buttonStyle(.plain)
        .disabled(impossible)
        .opacity(dimmed ? 0.32 : 1)
    }

    private func cellColor(_ scenario: Scenario, _ o: Double, impossible: Bool) -> Color {
        if impossible { return Color(hex: "c9c9c9") }
        let female = (scenario == .femHole || scenario == .femPlug)
        if highlight && female {
            let rounded = (o * 10000).rounded() / 10000
            if let ix = tops.firstIndex(of: rounded), ix < Self.rankColors.count {
                return Self.rankColors[ix]
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
