import Foundation

struct SizeRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date = .now
    var height: Double?      // cm
    var weight: Double?      // kg
    var foot: Double?        // cm
    var clothing: Int?       // 服サイズ 80,90,100...
    var shoe: Double?        // 靴サイズ cm
    var memo: String = ""
}

struct BrandNote: Identifiable, Codable, Hashable {
    var id = UUID()
    var brand: String = ""
    var category: String = "トップス"
    var size: String = ""
    var memo: String = ""
    static let categories = ["トップス", "ボトムス", "アウター", "肌着・パジャマ", "靴", "帽子", "その他"]
}

struct Child: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String = ""
    var birthday: Date?
    var colorIndex: Int = 0
    var records: [SizeRecord] = []
    var brandNotes: [BrandNote] = []

    var sorted: [SizeRecord] { records.sorted { $0.date < $1.date } }
    func latest<T>(_ k: KeyPath<SizeRecord, T?>) -> (T, Date)? {
        for r in records.sorted(by: { $0.date > $1.date }) { if let v = r[keyPath: k] { return (v, r.date) } }
        return nil
    }
    var ageText: String? {
        guard let b = birthday else { return nil }
        let c = Calendar.current.dateComponents([.year, .month], from: b, to: .now)
        return "\(c.year ?? 0)歳\(c.month ?? 0)か月"
    }
}

enum Fmt {
    static func n(_ v: Double, _ d: Int = 1) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.\(d)f", v)
    }
    static let date: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "yyyy年M月d日"; return f }()
    static let short: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "yy/M/d"; return f }()
}
