import SwiftUI

@main
struct RouterOffsetsApp: App {
    @State private var state = CalculatorState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(state)
        }
    }
}
