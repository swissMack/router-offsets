import SwiftUI

struct KitView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showClearConfirm = false

    private let chipColumns = [GridItem(.adaptive(minimum: 92))]

    var body: some View {
        @Bindable var appModel = appModel
        Form {
            Section {
                Toggle("Only show my kit", isOn: $appModel.kitFilterEnabled)
            } footer: {
                Text("Tick the guide bushes and cutters you actually own. Turn on the filter to hide everything else in the calculator, tables and inlay finder. Saved on this device.")
            }

            Section("Guide bushes") {
                chipGrid(for: Catalog.allBushes)
            }

            Section("Cutters") {
                chipGrid(for: Catalog.allCutters)
            }

            Section {
                Button("Clear kit", role: .destructive) {
                    showClearConfirm = true
                }
            }
        }
        .navigationTitle("My Kit")
        .confirmationDialog(
            "Clear all kit selections?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear kit", role: .destructive) {
                appModel.clearKit()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func chipGrid(for sizes: [Size]) -> some View {
        LazyVGrid(columns: chipColumns, spacing: 8) {
            ForEach(sizes) { size in
                chip(for: size)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func chip(for size: Size) -> some View {
        let owned = appModel.kit.contains(size.id)
        let label = Text(size.label).frame(maxWidth: .infinity)
        if owned {
            Button { appModel.toggleKit(size.id) } label: { label }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        } else {
            Button { appModel.toggleKit(size.id) } label: { label }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
}
