import SwiftUI

@main
struct SeichouApp: App {
    @StateObject private var store = DataStore()
    @StateObject private var purchase = Purchase()
    init() { Ads.start() }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(purchase)
                .tint(Theme.accent)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in Ads.requestATT() }
        }
    }
}

enum Theme {
    static let accent = Color(red: 0.16, green: 0.55, blue: 0.45)
    static let warm = Color(red: 0.97, green: 0.60, blue: 0.30)
    static let childColors: [Color] = [
        Color(red: 0.25, green: 0.55, blue: 0.85), Color(red: 0.93, green: 0.45, blue: 0.55),
        Color(red: 0.97, green: 0.60, blue: 0.30), Color(red: 0.45, green: 0.70, blue: 0.35),
        Color(red: 0.60, green: 0.45, blue: 0.80),
    ]
    static func color(_ i: Int) -> Color { childColors[((i % childColors.count) + childColors.count) % childColors.count] }
}

struct ContentView: View {
    @State private var tab = Showcase.initialTab
    var body: some View {
        VStack(spacing: 0) {
        TabView(selection: $tab) {
            HomeView().tabItem { Label("きろく", systemImage: "ruler.fill") }.tag(0)
            GraphTab().tabItem { Label("グラフ", systemImage: "chart.xyaxis.line") }.tag(1)
            SheetTab().tabItem { Label("サイズ表", systemImage: "square.and.arrow.up") }.tag(2)
            SettingsView().tabItem { Label("設定", systemImage: "gearshape.fill") }.tag(3)
        }
        AdBanner()
        }
    }
}
