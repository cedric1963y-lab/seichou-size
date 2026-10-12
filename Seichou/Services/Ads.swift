import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

enum Ads {
    #if DEBUG
    static let bannerID = "ca-app-pub-3940256099942544/2435281174"
    #else
    static let bannerID = "ca-app-pub-5342568663681412/2781022603"
    #endif
    /// スクショ撮影中は広告を出さない
    static var enabled: Bool { Showcase.scene == nil }
    private static var started = false

    @MainActor static func start() {
        guard enabled, !started else { return }
        started = true
        MobileAds.shared.start(completionHandler: nil)
    }
    /// 起動直後にATTを表示（バナーはATTの結果を待たずに読み込み済み。拒否時は非パーソナライズ）
    @MainActor static func requestATT() {
        guard enabled, ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}

struct BannerAdView: UIViewRepresentable {
    let width: CGFloat
    func makeUIView(context: Context) -> BannerView {
        let v = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        v.adUnitID = Ads.bannerID
        v.rootViewController = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        v.load(Request())
        return v
    }
    func updateUIView(_ v: BannerView, context: Context) {}
}

struct AdBanner: View {
    @EnvironmentObject var purchase: Purchase
    var body: some View {
        if Ads.enabled && !purchase.unlocked {
            GeometryReader { g in
                BannerAdView(width: g.size.width)
            }
            .frame(height: currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width).size.height)
        }
    }
}
