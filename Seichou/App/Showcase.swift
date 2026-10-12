import Foundation

/// Debug ビルドだけで使うストア用スクショのサンプル表示。リリースでは常に nil。
enum Showcase {
    static let scene: String? = {
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-SHOWCASE"), i + 1 < a.count { return a[i + 1] }
        #endif
        return nil
    }()
    static var initialTab: Int {
        switch scene { case "graph": 1; case "sheet": 2; default: 0 }
    }
    static let taroID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static func d(_ y: Int, _ m: Int, _ day: Int) -> Date {
        var c = DateComponents(); c.year = y; c.month = m; c.day = day; c.hour = 12
        return Calendar(identifier: .gregorian).date(from: c) ?? .now
    }
    static func sample() -> [Child] {
        var taro = Child(id: taroID, name: "たろう", birthday: d(2021, 5, 14), colorIndex: 0)
        let pts: [(Int, Int, Double, Double, Double, Int, Double)] = [
            (2024, 4, 92.5, 13.4, 14.0, 90, 14.5), (2024, 8, 95.0, 14.0, 14.5, 95, 15.0),
            (2024, 12, 97.8, 14.6, 15.0, 100, 15.5), (2025, 4, 100.2, 15.3, 15.5, 100, 16.0),
            (2025, 8, 102.9, 16.0, 16.0, 100, 16.5), (2025, 12, 105.1, 16.8, 16.5, 110, 17.0),
            (2026, 4, 107.6, 17.5, 17.0, 110, 17.5), (2026, 9, 110.4, 18.3, 17.5, 110, 18.0),
        ]
        taro.records = pts.map { SizeRecord(date: d($0.0, $0.1, 10), height: $0.2, weight: $0.3, foot: $0.4, clothing: $0.5, shoe: $0.6) }
        taro.records[7].memo = "保育園の身体測定"
        taro.brandNotes = [
            BrandNote(brand: "ユニクロ", category: "トップス", size: "110", memo: "ちょうど。袖は少し長め"),
            BrandNote(brand: "西松屋", category: "ボトムス", size: "110", memo: "ウエストゆったり"),
            BrandNote(brand: "イフミー", category: "靴", size: "18.0", memo: "幅広でぴったり"),
            BrandNote(brand: "プティマイン", category: "アウター", size: "120", memo: "冬はひと回り大きめ"),
        ]
        var hana = Child(name: "はなこ", birthday: d(2024, 2, 3), colorIndex: 1)
        let p2: [(Int, Int, Double, Double, Double, Int, Double)] = [
            (2025, 2, 75.0, 9.4, 11.5, 80, 12.0), (2025, 8, 80.6, 10.5, 12.5, 80, 13.0),
            (2026, 2, 85.2, 11.4, 13.0, 90, 13.5), (2026, 9, 89.0, 12.3, 13.5, 90, 14.0),
        ]
        hana.records = p2.map { SizeRecord(date: d($0.0, $0.1, 3), height: $0.2, weight: $0.3, foot: $0.4, clothing: $0.5, shoe: $0.6) }
        hana.brandNotes = [BrandNote(brand: "ユニクロ", category: "肌着・パジャマ", size: "90", memo: "")]
        return [taro, hana]
    }
}
