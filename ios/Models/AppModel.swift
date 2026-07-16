import SwiftUI
import Observation

@Observable
final class AppModel {
    var tableUnit: UnitSystem = .metric

    var kit: Set<String> = AppModel.loadKit() { didSet { Self.save(Array(kit), "kit") } }
    var kitFilterEnabled: Bool = UserDefaults.standard.bool(forKey: "kitFilter") {
        didSet { UserDefaults.standard.set(kitFilterEnabled, forKey: "kitFilter") }
    }
    private static func loadKit() -> Set<String> {
        (try? JSONDecoder().decode([String].self, from: UserDefaults.standard.data(forKey: "kit") ?? Data())).map(Set.init) ?? []
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
}
