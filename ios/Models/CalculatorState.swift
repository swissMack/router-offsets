import SwiftUI
import Observation

enum CalcMode { case forward, reverse }

@Observable
final class CalculatorState {
    var scenario: Scenario = .femHole
    var template: Double = 60
    var selectedTab: Int = 0

    var mode: CalcMode = .forward
    var depth: Double = 0
    var depthUnit: UnitSystem = .metric

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
        if let b = Catalog.allBushes.first(where: { $0.mm == bush }) {
            bushChoice = .standard(id: b.id)
        } else {
            bushChoice = .custom
            bushCustom = bush
            bushCustomUnit = .metric
        }
        if let c = Catalog.allCutters.first(where: { $0.mm == cutter }) {
            cutterChoice = .standard(id: c.id)
        } else {
            cutterChoice = .custom
            cutterCustom = cutter
            cutterCustomUnit = .metric
        }
    }
}
