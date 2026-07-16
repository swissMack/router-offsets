import SwiftUI
import Observation

enum CalcMode: Codable { case forward, reverse }

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

    func snapshot(name: String) -> SavedSetup {
        SavedSetup(
            name: name,
            scenario: scenario,
            bushChoice: bushChoice,
            cutterChoice: cutterChoice,
            bushCustom: bushCustom,
            bushCustomUnit: bushCustomUnit,
            cutterCustom: cutterCustom,
            cutterCustomUnit: cutterCustomUnit,
            template: template,
            templateUnit: templateUnit,
            depth: depth,
            depthUnit: depthUnit,
            mode: mode
        )
    }

    func apply(_ s: SavedSetup) {
        scenario = s.scenario
        bushChoice = s.bushChoice
        cutterChoice = s.cutterChoice
        bushCustom = s.bushCustom
        bushCustomUnit = s.bushCustomUnit
        cutterCustom = s.cutterCustom
        cutterCustomUnit = s.cutterCustomUnit
        template = s.template
        templateUnit = s.templateUnit
        depth = s.depth
        depthUnit = s.depthUnit
        mode = s.mode
    }
}
