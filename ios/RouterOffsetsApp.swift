import SwiftUI

@main
struct RouterOffsetsApp: App {
    @State private var state = CalculatorState()
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(state)
                .environment(appModel)
        }
    }
}
