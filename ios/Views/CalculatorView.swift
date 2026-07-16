import SwiftUI

struct CalculatorView: View {
    @Environment(CalculatorState.self) private var state

    private var isImpossible: Bool { Offsets.impossible(bush: state.bush, cutter: state.cutter) }
    private var offset: Double { Offsets.offset(state.scenario, bush: state.bush, cutter: state.cutter) }
    private var result: Double { state.scenario.resultSize(template: state.template, offset: offset) }

    var body: some View {
        @Bindable var state = state
        Form {
            Section("Scenario") {
                Picker("Scenario", selection: $state.scenario) {
                    ForEach(Scenario.allCases) { Text($0.longLabel).tag($0) }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Hardware") {
                Picker("Guide bush Ø", selection: $state.bush) {
                    ForEach(Offsets.bushes, id: \.self) { Text("\(Offsets.fmt($0)) mm").tag($0) }
                }
                Picker("Cutter Ø", selection: $state.cutter) {
                    ForEach(Offsets.cutters, id: \.self) { Text("\(Offsets.fmt($0)) mm").tag($0) }
                }
                LabeledContent("Template Ø (mm)") {
                    TextField("Template", value: $state.template, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Result") {
                if isImpossible {
                    Label("Impossible — a \(Offsets.fmt(state.cutter)) mm cutter cannot pass a \(Offsets.fmt(state.bush)) mm guide bush.",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Offset: \(Offsets.fmt(offset)) mm")
                            .font(.title).bold()
                            .foregroundStyle(.tint)
                        Text("offset = \(state.scenario.formula) = (\(Offsets.fmt(state.bush)) \(state.scenario.isDiff ? "−" : "+") \(Offsets.fmt(state.cutter))) / 2")
                            .font(.footnote).foregroundStyle(.secondary)
                        if state.template > 0 {
                            if result > 0 {
                                Text("\(state.scenario.piece) Ø: \(Offsets.fmt(result)) mm (\(state.scenario.piece.lowercased()) is \(state.scenario.rel))")
                                Text("\(state.scenario.piece) = \(state.scenario.resultFormula) = \(Offsets.fmt(state.template)) \(state.scenario.sign < 0 ? "−" : "+") 2×\(Offsets.fmt(offset))")
                                    .font(.footnote).foregroundStyle(.secondary)
                            } else {
                                Text("Template too small — the offset consumes the whole opening.")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            Section("Cross-section") {
                DiagramView(scenario: state.scenario,
                            bush: state.bush,
                            cutter: state.cutter,
                            offset: isImpossible ? nil : offset)
                    .padding(.vertical, 4)
                Text("\(state.scenario.name): the guide bush (grey) rides the template edge; the cutter (purple) cuts offset from it. The \(state.scenario.piece.lowercased()) ends up \(state.scenario.rel).")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Calculator")
    }
}

extension Scenario {
    var longLabel: String {
        switch self {
        case .femHole:  return "Female → Hole (smaller)"
        case .femPlug:  return "Female → Plug (smaller)"
        case .maleHole: return "Male → Hole (bigger)"
        case .malePlug: return "Male → Plug (bigger)"
        }
    }
}
