import SwiftUI
import Observation

struct SavedSetup: Codable, Identifiable {
    var id = UUID()
    var name: String
    var scenario: Scenario
    var bushChoice: SizeChoice
    var cutterChoice: SizeChoice
    var bushCustom: Double
    var bushCustomUnit: UnitSystem
    var cutterCustom: Double
    var cutterCustomUnit: UnitSystem
    var template: Double
    var templateUnit: UnitSystem
    var depth: Double
    var depthUnit: UnitSystem
    var mode: CalcMode
}

@Observable
final class AppModel {
    var units: UnitSystem = UnitSystem(rawValue: UserDefaults.standard.string(forKey: "units") ?? "m") ?? .metric {
        didSet { UserDefaults.standard.set(units.rawValue, forKey: "units") }
    }

    var kit: Set<String> = AppModel.loadKit() { didSet { Self.save(Array(kit), "kit") } }
    var kitFilterEnabled: Bool = UserDefaults.standard.bool(forKey: "kitFilter") {
        didSet { UserDefaults.standard.set(kitFilterEnabled, forKey: "kitFilter") }
    }
    var setups: [SavedSetup] = AppModel.loadSetups() { didSet { Self.save(setups, "setups") } }
    private static func loadKit() -> Set<String> {
        (try? JSONDecoder().decode([String].self, from: UserDefaults.standard.data(forKey: "kit") ?? Data())).map(Set.init) ?? []
    }
    private static func loadSetups() -> [SavedSetup] {
        (try? JSONDecoder().decode([SavedSetup].self, from: UserDefaults.standard.data(forKey: "setups") ?? Data())) ?? []
    }
    private static func save<T: Encodable>(_ v: T, _ key: String) {
        UserDefaults.standard.set(try? JSONEncoder().encode(v), forKey: key)
    }
    func kitActive(_ c: SizeCategory) -> Bool {
        guard kitFilterEnabled else { return false }
        let arr = c == .bush ? Catalog.allBushes : Catalog.allCutters
        return arr.contains { kit.contains($0.id) }
    }
    func isVisible(_ c: SizeCategory, _ s: Size) -> Bool { kitActive(c) ? kit.contains(s.id) : true }
    func toggleKit(_ id: String) { if kit.contains(id) { kit.remove(id) } else { kit.insert(id) } }
    func clearKit() { kit.removeAll() }
    func addSetup(_ s: SavedSetup) { setups.append(s) }
    func deleteSetup(_ s: SavedSetup) { setups.removeAll { $0.id == s.id } }
}
