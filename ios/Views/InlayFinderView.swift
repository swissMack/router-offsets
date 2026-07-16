import SwiftUI

struct InlayFinderView: View {
    @Environment(AppModel.self) private var appModel
    @State private var template: Double = 60
    @State private var templateUnit: UnitSystem = .metric
    @State private var selectedOffset: Double = 8
    @FocusState private var templateFocused: Bool

    private var pairs: [InlayPairV2] {
        let kb = appModel.kitActive(.bush)
        let kc = appModel.kitActive(.cutter)
        func inKit(_ s: SizePair) -> Bool {
            (!kb || appModel.kit.contains(s.bush.id)) && (!kc || appModel.kit.contains(s.cutter.id))
        }
        return pairOffsets(appModel.tableUnit).compactMap { p -> InlayPairV2? in
            let holes = p.holes.filter(inKit)
            let plugs = p.plugs.filter(inKit)
            guard !holes.isEmpty, !plugs.isEmpty else { return nil }
            return InlayPairV2(mm: p.mm, holes: holes, plugs: plugs, count: holes.count + plugs.count)
        }
    }

    private var pair: InlayPairV2? {
        pairs.first { abs($0.mm - selectedOffset) < 0.001 }
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Template Ø") {
                    HStack {
                        TextField("Template", value: $template, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($templateFocused)
                            .selectAllOnEditing()
                        Picker("", selection: $templateUnit) {
                            Text("mm").tag(UnitSystem.metric); Text("in").tag(UnitSystem.imperial)
                        }.pickerStyle(.segmented).frame(width: 110)
                    }
                }
                Picker("Target offset", selection: $selectedOffset) {
                    ForEach(pairs) { p in
                        Text(appModel.tableUnit == .metric ? "\(fmtN(p.mm)) mm" : fracIn(p.mm)).tag(p.mm)
                    }
                }
                .onChange(of: appModel.tableUnit) { _, _ in syncSelectedOffset() }
                .onChange(of: appModel.kit) { _, _ in syncSelectedOffset() }
                .onChange(of: appModel.kitFilterEnabled) { _, _ in syncSelectedOffset() }
                .onAppear { syncSelectedOffset() }
            } header: {
                Text("Inlay Pair Finder")
            } footer: {
                Text("For inlay work the hole and the plug are cut from the SAME template and their offsets must be equal. The hole uses offset (B−C)/2, the plug uses (B+C)/2 — so you need two different setups that give the same offset.")
            }

            resultSection
        }
        .navigationTitle("Inlay Finder")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneBar(isFocused: $templateFocused)
    }

    private func syncSelectedOffset() {
        guard !pairs.contains(where: { abs($0.mm - selectedOffset) < 0.001 }) else { return }
        selectedOffset = pairs.first?.mm ?? 8
    }

    @ViewBuilder
    private var resultSection: some View {
        if let pair {
            let o = pair.mm
            let T = toMM(template, templateUnit)
            let size = T > 2 * o ? T - 2 * o : nil

            Section {
                if let size {
                    Text("With a \(both(T)) template and a \(both(o)) offset, both hole and plug come out at \(both(size)) — a perfect-fit inlay.")
                        .font(.headline).foregroundStyle(.tint)
                } else {
                    Text("Template must be larger than \(both(2 * o)) for this offset.")
                        .foregroundStyle(.red)
                }
            }

            Section("Hole setups — offset = (B−C)/2") {
                setupTable(pair.holes)
            }
            Section("Plug setups — offset = (B+C)/2") {
                setupTable(pair.plugs)
            }

            Section {
                Text("Pick one setup from each list. Ideally choose a pair sharing the same cutter or bush so you only swap one part between cuts.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        } else {
            Section {
                Text("No matching hole+plug offset pairs — widen your kit selection or switch the chart units above.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func setupTable(_ setups: [SizePair]) -> some View {
        ForEach(setups, id: \.self) { s in
            HStack {
                Text("Bush \(s.bush.label)")
                Spacer()
                Text("Cutter \(s.cutter.label)").foregroundStyle(.secondary)
            }
        }
    }
}
