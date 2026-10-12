import Foundation
import SwiftUI

@MainActor
final class DataStore: ObservableObject {
    static let freeChildren = 1
    static let freeRecords = 5
    @Published var children: [Child] = [] { didSet { save() } }
    private let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("children.json")

    init() {
        if Showcase.scene != nil { children = Showcase.sample(); return }
        if let d = try? Data(contentsOf: url), let c = try? JSONDecoder().decode([Child].self, from: d) { children = c }
    }
    private func save() {
        guard Showcase.scene == nil else { return }
        if let d = try? JSONEncoder().encode(children) { try? d.write(to: url, options: .atomic) }
    }
    var totalRecords: Int { children.reduce(0) { $0 + $1.records.count } }
    func canAddChild(_ unlocked: Bool) -> Bool { unlocked || children.count < Self.freeChildren }
    func canAddRecord(_ unlocked: Bool) -> Bool { unlocked || totalRecords < Self.freeRecords }
    func index(_ id: UUID) -> Int? { children.firstIndex { $0.id == id } }
}
