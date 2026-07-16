import SwiftUI

struct CalculatorView: View {
    @Environment(CalculatorState.self) private var state
    @FocusState private var fieldFocused: Bool

    private var bushMM: Double? { state.bushMM }
    private var cutterMM: Double? { state.cutterMM }
    private var isImpossible: Bool {
        guard let b = bushMM, let c = cutterMM else { return false }
        return Offsets.impossible(bush: b, cutter: c)
    }
    private var offset: Double? {
        guard let b = bushMM, let c = cutterMM, !isImpossible else { return nil }
        return Offsets.offset(state.scenario, bush: b, cutter: c)
    }

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
                Picker("Guide bush Ø", selection: $state.bushChoice) { sizeOptions(Catalog.bushes) }
                    .pickerStyle(.navigationLink)
                if state.bushChoice == .custom {
                    HStack {
                        TextField("Custom Ø", value: $state.bushCustom, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .focused($fieldFocused).selectAllOnEditing()
                        Picker("", selection: $state.bushCustomUnit) {
                            Text("mm").tag(UnitSystem.metric); Text("in").tag(UnitSystem.imperial)
                        }.pickerStyle(.segmented).frame(width: 110)
                    }
                }

                Picker("Cutter Ø", selection: $state.cutterChoice) { sizeOptions(Catalog.cutters) }
                    .pickerStyle(.navigationLink)
                if state.cutterChoice == .custom {
                    HStack {
                        TextField("Custom Ø", value: $state.cutterCustom, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .focused($fieldFocused).selectAllOnEditing()
                        Picker("", selection: $state.cutterCustomUnit) {
                            Text("mm").tag(UnitSystem.metric); Text("in").tag(UnitSystem.imperial)
                        }.pickerStyle(.segmented).frame(width: 110)
                    }
                }

                LabeledContent("Template Ø") {
                    HStack {
                        TextField("Template", value: $state.template, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($fieldFocused).selectAllOnEditing()
                        Picker("", selection: $state.templateUnit) {
                            Text("mm").tag(UnitSystem.metric); Text("in").tag(UnitSystem.imperial)
                        }.pickerStyle(.segmented).frame(width: 110)
                    }
                }
            }

            Section("Result") {
                resultContent
            }

            Section("Cross-section") {
                DiagramView(scenario: state.scenario, bush: bushMM ?? 20, cutter: cutterMM ?? 8,
                            offset: isImpossible ? nil : offset)
                    .padding(.vertical, 4)
                Text("\(state.scenario.name): the guide bush (grey) rides the template edge; the cutter (purple) cuts offset from it. The \(state.scenario.piece.lowercased()) ends up \(state.scenario.rel).")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Calculator")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneBar(isFocused: $fieldFocused)
    }

    @ViewBuilder private func sizeOptions(_ sets: [[Size]]) -> some View {
        Section("Metric")   { ForEach(sets[0]) { Text($0.label).tag(SizeChoice.standard(id: $0.id)) } }
        Section("Imperial") { ForEach(sets[1]) { Text($0.label).tag(SizeChoice.standard(id: $0.id)) } }
        Text("Custom…").tag(SizeChoice.custom)
    }

    @ViewBuilder private var resultContent: some View {
        if let b = bushMM, let c = cutterMM {
            if isImpossible {
                Label("Impossible — a \(both(c)) cutter cannot pass a \(both(b)) guide bush.",
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if let o = offset {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Offset: \(fmtN(o)) mm (\(fracIn(o)))")
                        .font(.title).bold()
                        .foregroundStyle(.tint)
                    Text("offset = \(state.scenario.formula) = (\(fmtN(b)) \(state.scenario.isDiff ? "−" : "+") \(fmtN(c))) / 2 mm")
                        .font(.footnote).foregroundStyle(.secondary)
                    let t = toMM(state.template, state.templateUnit)
                    let r = state.scenario.resultSize(template: t, offset: o)
                    if t > 0 {
                        if r > 0 {
                            Text("\(state.scenario.piece) Ø: \(both(r)) (\(state.scenario.rel))")
                            Text("\(state.scenario.piece) = \(state.scenario.resultFormula) = \(fmtN(t)) \(state.scenario.sign < 0 ? "−" : "+") 2×\(fmtN(o))")
                                .font(.footnote).foregroundStyle(.secondary)
                        } else {
                            Text("Template too small — the offset consumes the whole opening.")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        } else {
            Text("Enter bush and cutter diameters.")
                .foregroundStyle(.secondary)
        }
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
