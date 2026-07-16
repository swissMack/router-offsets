import SwiftUI
import Observation

@Observable
final class CalculatorState {
    var scenario: Scenario = .femHole
    var bush: Double = 24
    var cutter: Double = 8
    var template: Double = 60
    var selectedTab: Int = 0

    func load(scenario: Scenario, bush: Double, cutter: Double) {
        self.scenario = scenario
        self.bush = bush
        self.cutter = cutter
    }
}
