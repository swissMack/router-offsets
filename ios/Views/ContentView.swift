import SwiftUI

struct ContentView: View {
    @Environment(CalculatorState.self) private var state

    var body: some View {
        @Bindable var state = state
        TabView(selection: $state.selectedTab) {
            NavigationStack { CalculatorView() }
                .tabItem { Label("Calculator", systemImage: "slider.horizontal.3") }
                .tag(0)
            NavigationStack { TablesView() }
                .tabItem { Label("Tables", systemImage: "tablecells") }
                .tag(1)
            NavigationStack { InlayFinderView() }
                .tabItem { Label("Inlay", systemImage: "square.on.square") }
                .tag(2)
            NavigationStack { KitView() }
                .tabItem { Label("Kit", systemImage: "hammer") }
                .tag(3)
            NavigationStack { MathsView() }
                .tabItem { Label("Maths", systemImage: "function") }
                .tag(4)
        }
    }
}
