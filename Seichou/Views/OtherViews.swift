import SwiftUI
import Charts

struct ChildPicker: View {
    @EnvironmentObject var store: DataStore
    @Binding var id: UUID?
    var body: some View {
        if store.children.count > 1 {
            Picker("子ども", selection: $id) {
                ForEach(store.children) { Text($0.name).tag(UUID?.some($0.id)) }
            }.pickerStyle(.segmented)
        }
    }
}

enum Metric: String, CaseIterable, Identifiable {
    case height = "身長", weight = "体重", foot = "足", clothing = "服", shoe = "靴"
    var id: String { rawValue }
    var unit: String { switch self { case .weight: "kg"; case .clothing: ""; default: "cm" } }
    func value(_ r: SizeRecord) -> Double? {
        switch self { case .height: r.height; case .weight: r.weight; case .foot: r.foot; case .clothing: r.clothing.map(Double.init); case .shoe: r.shoe }
    }
}

struct LockedView: View {
    let title: String; let text: String
    @State private var paywall = false
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "lock.fill")
        } description: { Text(text) } actions: {
            Button("全機能版について") { paywall = true }.buttonStyle(.borderedProminent)
        }.sheet(isPresented: $paywall) { PaywallView() }
    }
}

struct GraphTab: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var purchase: Purchase
    @State private var id: UUID?
    @State private var metric: Metric = .height
    var body: some View {
        NavigationStack {
            Group {
                if !purchase.unlocked {
                    LockedView(title: "成長グラフ", text: "身長・体重・足・服や靴のサイズの変化をグラフで見られます。")
                } else if let c = store.children.first(where: { $0.id == id }) ?? store.children.first {
                    let pts = c.sorted.compactMap { r in metric.value(r).map { (r.date, $0) } }
                    List {
                        Section {
                            ChildPicker(id: $id)
                            Picker("項目", selection: $metric) { ForEach(Metric.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                        }
                        Section {
                            if pts.count < 2 { Text("2回以上記録するとグラフになります").foregroundStyle(.secondary) }
                            Chart {
                                ForEach(pts, id: \.0) { p in
                                    AreaMark(x: .value("日付", p.0), yStart: .value("", pts.map(\.1).min()! * 0.95), yEnd: .value(metric.rawValue, p.1))
                                        .foregroundStyle(Theme.color(c.colorIndex).opacity(0.12).gradient).interpolationMethod(.monotone)
                                    LineMark(x: .value("日付", p.0), y: .value(metric.rawValue, p.1))
                                        .foregroundStyle(Theme.color(c.colorIndex)).interpolationMethod(.monotone).lineStyle(StrokeStyle(lineWidth: 3))
                                    PointMark(x: .value("日付", p.0), y: .value(metric.rawValue, p.1)).foregroundStyle(Theme.color(c.colorIndex))
                                }
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 300).padding(.vertical, 8)
                        } header: { Text("\(c.name)の\(metric.rawValue)" + (metric.unit.isEmpty ? "" : "（\(metric.unit)）")) }
                        Section("記録") {
                            ForEach(pts.reversed(), id: \.0) { p in
                                HStack { Text(Fmt.date.string(from: p.0)); Spacer(); Text(Fmt.n(p.1) + " " + metric.unit).bold().monospacedDigit() }
                            }
                        }
                        if let f = pts.first, let l = pts.last, pts.count > 1 {
                            Section { Text("\(Fmt.date.string(from: f.0))から ＋\(Fmt.n(l.1 - f.1)) \(metric.unit)").foregroundStyle(Theme.accent).bold() }
                        }
                    }
                } else { ContentUnavailableView("まだ子どもが登録されていません", systemImage: "chart.xyaxis.line") }
            }.navigationTitle("成長グラフ")
        }
    }
}

struct SizeSheetCard: View {
    let child: Child
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Avatar(child: child, size: 52)
                VStack(alignment: .leading) {
                    Text("\(child.name)のサイズ表").font(.title2.bold())
                    Text(Fmt.date.string(from: .now) + " 現在" + (child.ageText.map { "・" + $0 } ?? "")).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                row("身長", child.latest(\.height).map { Fmt.n($0.0) + " cm" })
                row("体重", child.latest(\.weight).map { Fmt.n($0.0) + " kg" })
                row("足の長さ", child.latest(\.foot).map { Fmt.n($0.0) + " cm" })
                row("服のサイズ", child.latest(\.clothing).map { "\($0.0)" })
                row("靴のサイズ", child.latest(\.shoe).map { Fmt.n($0.0) + " cm" })
            }
            if !child.brandNotes.isEmpty {
                Divider()
                Text("ブランド別").font(.headline)
                ForEach(child.brandNotes) { n in
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(n.brand)（\(n.category)）")
                        Spacer()
                        Text(n.size).bold()
                    }.font(.subheadline)
                    if !n.memo.isEmpty { Text(n.memo).font(.caption).foregroundStyle(.secondary) }
                }
            }
            Text("プレゼントの参考にどうぞ").font(.footnote).foregroundStyle(Theme.accent).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(22).frame(width: 360)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.color(child.colorIndex).opacity(0.5), lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .environment(\.colorScheme, .light)
    }
    func row(_ t: String, _ v: String?) -> some View {
        GridRow { Text(t).foregroundStyle(.secondary); Text(v ?? "—").font(.title3.bold()).monospacedDigit() }
    }
}

struct SheetTab: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var purchase: Purchase
    @State private var id: UUID?
    var body: some View {
        NavigationStack {
            Group {
                if !purchase.unlocked {
                    LockedView(title: "サイズ表を送る", text: "いまのサイズをまとめた画像・PDFを、LINEやメールでおじいちゃん・おばあちゃんに送れます。")
                } else if let c = store.children.first(where: { $0.id == id }) ?? store.children.first {
                    ScrollView {
                        VStack(spacing: 18) {
                            ChildPicker(id: $id).padding(.horizontal)
                            SizeSheetCard(child: c).shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                            HStack {
                                if let img = Exporter.image(c) {
                                    ShareLink(item: img, preview: SharePreview("\(c.name)のサイズ表", image: img)) {
                                        Label("画像で送る", systemImage: "photo").frame(maxWidth: .infinity)
                                    }.buttonStyle(.borderedProminent)
                                }
                                if let pdf = Exporter.pdf(c) {
                                    ShareLink(item: pdf) { Label("PDFで送る", systemImage: "doc.richtext").frame(maxWidth: .infinity) }.buttonStyle(.bordered)
                                }
                            }.padding(.horizontal, 24)
                        }.padding(.vertical)
                    }.background(Color(.systemGroupedBackground))
                } else { ContentUnavailableView("まだ子どもが登録されていません", systemImage: "person.crop.rectangle") }
            }.navigationTitle("サイズ表")
        }
    }
}

@MainActor
enum Exporter {
    static func image(_ c: Child) -> Image? {
        let r = ImageRenderer(content: SizeSheetCard(child: c).padding(8).background(Color.white)); r.scale = 3
        return r.uiImage.map { Image(uiImage: $0) }
    }
    static func pdf(_ c: Child) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(c.name)のサイズ表.pdf")
        let r = ImageRenderer(content: SizeSheetCard(child: c).padding(20).background(Color.white))
        var ok = false
        r.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            ctx.beginPDFPage(nil); draw(ctx); ctx.endPDFPage(); ctx.closePDF(); ok = true
        }
        return ok ? url : nil
    }
}

struct PaywallView: View {
    @EnvironmentObject var purchase: Purchase
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "ruler.fill").font(.system(size: 44)).foregroundStyle(Theme.accent)
                        Text("全機能版").font(.title2.bold())
                        Text("一度買えばずっと使えます（買い切り）").font(.subheadline).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity).padding(.vertical)
                }
                Section {
                    Label("子どもの人数・記録の数が無制限", systemImage: "person.2.fill")
                    Label("ブランド別のサイズメモ", systemImage: "tag.fill")
                    Label("成長グラフ（身長・体重・足・服・靴）", systemImage: "chart.xyaxis.line")
                    Label("サイズ表を画像・PDFで送る", systemImage: "square.and.arrow.up")
                } footer: { Text("無料版は子ども\(DataStore.freeChildren)人・記録\(DataStore.freeRecords)件まで使えます。") }
                Section {
                    if purchase.unlocked { Label("購入済みです", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.accent) }
                    else {
                        Button { Task { await purchase.buy(); if purchase.unlocked { dismiss() } } } label: {
                            Text(purchase.product.map { "\($0.displayPrice)で購入" } ?? "購入する").bold().frame(maxWidth: .infinity)
                        }.disabled(purchase.busy)
                        Button("購入を復元") { Task { await purchase.restore() } }.frame(maxWidth: .infinity)
                    }
                }
                if let m = purchase.message { Text(m).font(.footnote).foregroundStyle(.secondary) }
            }
            .toolbar { Button("閉じる") { dismiss() } }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var purchase: Purchase
    @State private var paywall = false
    var body: some View {
        NavigationStack {
            List {
                Section("全機能版") {
                    if purchase.unlocked { Label("購入済み", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.accent) }
                    else { Button("全機能版について") { paywall = true } }
                    Button("購入を復元") { Task { await purchase.restore() } }
                    if let m = purchase.message { Text(m).font(.footnote).foregroundStyle(.secondary) }
                }
                Section("このアプリについて") {
                    Link("サポート", destination: URL(string: "https://cedric1963y-lab.github.io/seichou-size/")!)
                    Link("プライバシーポリシー", destination: URL(string: "https://cedric1963y-lab.github.io/seichou-size/privacy.html")!)
                    Link("利用規約（EULA）", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    LabeledContent("バージョン", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                }
                Section { Text("データはこのiPhoneの中だけに保存されます。アカウント登録や広告はありません。").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $paywall) { PaywallView() }
        }
    }
}
