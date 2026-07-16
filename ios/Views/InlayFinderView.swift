import SwiftUI

struct InlayFinderView: View {
    private let pairs = Offsets.inlayPairs()
    @State private var template: Double = 60
    @State private var selectedOffset: Double = 8
    @FocusState private var templateFocused: Bool

    private var pair: InlayPair? { pairs.first { $0.offset == selectedOffset } }

    var body: some View {
        Form {
            Section {
                LabeledContent("Template Ø (mm)") {
                    TextField("Template", value: $template, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($templateFocused)
                        .selectAllOnEditing()
                }
                Picker("Target offset", selection: $selectedOffset) {
                    ForEach(pairs) { Text("\(Offsets.fmt($0.offset)) mm").tag($0.offset) }
                }
            } header: {
                Text("Inlay Pair Finder")
            } footer: {
                Text("Hole and plug are cut from the SAME template and their offsets must be equal. Hole uses (B−C)/2, plug uses (B+C)/2.")
            }

            if let pair {
                let o = pair.offset
                Section {
                    if template > 2 * o {
                        Text("Both hole and plug come out at \(Offsets.fmt(template - 2 * o)) mm Ø — a perfect-fit inlay.")
                            .font(.headline).foregroundStyle(.tint)
                    } else {
                        Text("Template must be larger than \(Offsets.fmt(2 * o)) mm for this offset.")
                            .foregroundStyle(.red)
                    }
                }

                Section("Hole setups — offset = (B−C)/2 = \(Offsets.fmt(o))") {
                    setupTable(pair.holes)
                }
                Section("Plug setups — offset = (B+C)/2 = \(Offsets.fmt(o))") {
                    setupTable(pair.plugs)
                }

                Section {
                    Text("Pick one setup from each list. Ideally choose a pair sharing the same cutter or bush so you only swap one part between cuts.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Inlay Finder")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneBar(isFocused: $templateFocused)
    }

    private func setupTable(_ setups: [Setup]) -> some View {
        ForEach(setups) { s in
            HStack {
                Text("Bush \(Offsets.fmt(s.bush)) mm")
                Spacer()
                Text("Cutter \(Offsets.fmt(s.cutter)) mm").foregroundStyle(.secondary)
            }
        }
    }
}
