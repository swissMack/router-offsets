import SwiftUI

struct CalculatorView: View {
    @Environment(CalculatorState.self) private var state
    @Environment(AppModel.self) private var appModel
    @FocusState private var fieldFocused: Bool
    @State private var showSaveAlert = false
    @State private var newSetupName = ""

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

    private func disp(_ mm: Double) -> String {
        appModel.units == .metric ? "\(fmtN(mm)) mm" : fracIn(mm)
    }

    private func syncUnits() {
        state.templateUnit = appModel.units
        state.depthUnit = appModel.units
        state.bushCustomUnit = appModel.units
        state.cutterCustomUnit = appModel.units
    }

    private func resetChoicesForUnit() {
        if appModel.units == .metric {
            state.bushChoice = .standard(id: "m24")
            state.cutterChoice = .standard(id: "m8")
        } else {
            state.bushChoice = .standard(id: "i3-4")
            state.cutterChoice = .standard(id: "i5-16")
        }
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
                Picker("Guide bush Ø", selection: $state.bushChoice) { sizeOptions(Catalog.bushes, .bush) }
                    .pickerStyle(.navigationLink)
                if state.bushChoice == .custom {
                    TextField("Custom Ø", value: $state.bushCustom, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .focused($fieldFocused).selectAllOnEditing()
                }

                Picker("Cutter Ø", selection: $state.cutterChoice) { sizeOptions(Catalog.cutters, .cutter) }
                    .pickerStyle(.navigationLink)
                if state.cutterChoice == .custom {
                    TextField("Custom Ø", value: $state.cutterCustom, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .focused($fieldFocused).selectAllOnEditing()
                }

                Picker("Mode", selection: $state.mode) {
                    Text("I have a template → size the result").tag(CalcMode.forward)
                    Text("I want a result → size the template").tag(CalcMode.reverse)
                }
                .pickerStyle(.segmented)

                LabeledContent(state.mode == .forward ? "Template opening / disc Ø" : "Target \(state.scenario.piece.lowercased()) Ø") {
                    TextField("Template", value: $state.template, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($fieldFocused).selectAllOnEditing()
                }

                LabeledContent("Cut depth (optional)") {
                    TextField("Depth", value: $state.depth, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($fieldFocused).selectAllOnEditing()
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

            Section("Saved setups") {
                Button {
                    newSetupName = ""
                    showSaveAlert = true
                } label: {
                    Label("Save this setup", systemImage: "star.fill")
                }

                if appModel.setups.isEmpty {
                    Text("No saved setups yet — configure the calculator and tap Save.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(appModel.setups) { setup in
                        Button {
                            appModel.units = setup.templateUnit
                            state.apply(setup)
                        } label: {
                            Label("★ \(setup.name)", systemImage: "star.fill")
                                .labelStyle(.titleOnly)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                appModel.deleteSetup(setup)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                appModel.deleteSetup(setup)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Calculator")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneBar(isFocused: $fieldFocused)
        .onAppear { syncUnits() }
        .onChange(of: appModel.units) { _, _ in
            syncUnits()
            resetChoicesForUnit()
        }
        .alert("Save this setup", isPresented: $showSaveAlert) {
            TextField("Setup name", text: $newSetupName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = newSetupName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    appModel.addSetup(state.snapshot(name: trimmed))
                }
                newSetupName = ""
            }
        } message: {
            Text("Give this setup a name, e.g. “Hinge recess jig”.")
        }
    }

    @ViewBuilder private func sizeOptions(_ sets: [[Size]], _ category: SizeCategory) -> some View {
        let active = sets[appModel.units == .metric ? 0 : 1].filter { appModel.isVisible(category, $0) }
        ForEach(active) { Text($0.label).tag(SizeChoice.standard(id: $0.id)) }
        Text("Custom…").tag(SizeChoice.custom)
    }

    @ViewBuilder private var resultContent: some View {
        if let b = bushMM, let c = cutterMM {
            if isImpossible {
                Label("Impossible — a \(disp(c)) cutter cannot pass a \(disp(b)) guide bush.",
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if let o = offset {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Offset: \(disp(o))")
                        .font(.title).bold()
                        .foregroundStyle(.tint)
                    Text("offset = \(state.scenario.formula) = (\(disp(b)) \(state.scenario.isDiff ? "−" : "+") \(disp(c))) / 2")
                        .font(.footnote).foregroundStyle(.secondary)
                    let t = toMM(state.template, state.templateUnit)
                    if t > 0 {
                        switch state.mode {
                        case .forward:
                            let r = state.scenario.resultSize(template: t, offset: o)
                            if r > 0 {
                                Text("\(state.scenario.piece) Ø: \(disp(r)) (\(state.scenario.rel))")
                                Text("\(state.scenario.piece) = \(state.scenario.resultFormula) = \(disp(t)) \(state.scenario.sign < 0 ? "−" : "+") 2×\(disp(o))")
                                    .font(.footnote).foregroundStyle(.secondary)
                            } else {
                                Text("Template too small — the offset consumes the whole opening.")
                                    .foregroundStyle(.red)
                            }
                        case .reverse:
                            let template = t - Double(state.scenario.sign) * 2 * o
                            if template > 0 {
                                Text("Make the template: \(disp(template))")
                                Text("Template = \(state.scenario.piece) \(state.scenario.sign < 0 ? "+" : "−") 2×offset = \(disp(t)) \(state.scenario.sign < 0 ? "+" : "−") 2×\(disp(o))")
                                    .font(.footnote).foregroundStyle(.secondary)
                            } else {
                                Text("Not achievable — this setup's offset is too large for that target size.")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    Text("↳ Corners: internal corners of the cut will have a radius of at least \(disp(c / 2)) (cutter radius). Template internal corners tighter than \(disp(b / 2)) radius won't be followed by the bush.")
                        .font(.footnote).foregroundStyle(.secondary)

                    let dep = toMM(state.depth, state.depthUnit)
                    if dep > 0 {
                        let per = c / 2
                        let n = max(1, Int(ceil(dep / per)))
                        Text("↳ Depth: \(disp(dep)) deep with a \(disp(c)) cutter → \(n) pass\(n > 1 ? "es" : "") of \(disp(dep / Double(n))) (rule of thumb: ≤ half the cutter Ø per pass in hardwood).")
                            .font(.footnote).foregroundStyle(.secondary)
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
