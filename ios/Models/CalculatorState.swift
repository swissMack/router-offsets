import SwiftUI
import Observation

@Observable
final class CalculatorState {
    var scenario: Scenario = .femHole
    var bush: Double = 24
    var cutter: Double = 8
    var template: Double = 60
    var selectedTab: Int = 0

    var bushChoice: SizeChoice = .standard(id: "m24")
    var cutterChoice: SizeChoice = .standard(id: "m8")
    var bushCustom: Double = 0
    var bushCustomUnit: UnitSystem = .metric
    var cutterCustom: Double = 0
    var cutterCustomUnit: UnitSystem = .metric
    var templateUnit: UnitSystem = .metric

    var bushMM: Double? { resolve(bushChoice, custom: bushCustom, unit: bushCustomUnit) }
    var cutterMM: Double? { resolve(cutterChoice, custom: cutterCustom, unit: cutterCustomUnit) }

    private func resolve(_ choice: SizeChoice, custom: Double, unit: UnitSystem) -> Double? {
        switch choice {
        case .standard(let id): return Catalog.size(id: id)?.mm
        case .custom: return custom > 0 ? toMM(custom, unit) : nil
        }
    }

    func load(scenario: Scenario, bush: Double, cutter: Double) {
        self.scenario = scenario
        self.bush = bush
        self.cutter = cutter
    }
}
