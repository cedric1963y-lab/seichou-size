import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var purchase: Purchase
    @State private var path: [UUID] = (Showcase.scene == "detail" || Showcase.scene == "brand" || Showcase.scene == "record") ? [Showcase.taroID] : []
    @State private var editingChild: Child?
    @State private var paywall = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if store.children.isEmpty {
                    ContentUnavailableView("子どもを登録しましょう", systemImage: "figure.and.child.holdinghands",
                                           description: Text("右上の＋から名前を登録すると、身長・体重・足のサイズ・服や靴のサイズを記録できます。"))
                }
                ForEach(store.children) { c in
                    NavigationLink(value: c.id) { ChildCard(child: c) }
                }
                .onDelete { store.children.remove(atOffsets: $0) }
            }
            .navigationTitle("成長サイズ帳")
            .navigationDestination(for: UUID.self) { ChildDetailView(childID: $0) }
            .toolbar {
                Button { if store.canAddChild(purchase.unlocked) { editingChild = Child(colorIndex: store.children.count) } else { paywall = true } }
                label: { Image(systemName: "plus") }
            }
            .sheet(item: $editingChild) { c in ChildEditView(child: c) }
            .sheet(isPresented: $paywall) { PaywallView() }
        }
    }
}

struct ChildCard: View {
    let child: Child
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Avatar(child: child, size: 44)
                VStack(alignment: .leading) {
                    Text(child.name).font(.title3.bold())
                    if let a = child.ageText { Text(a).font(.subheadline).foregroundStyle(.secondary) }
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Pill(title: "身長", value: child.latest(\.height).map { Fmt.n($0.0) + "cm" })
                Pill(title: "服", value: child.latest(\.clothing).map { "\($0.0)" })
                Pill(title: "靴", value: child.latest(\.shoe).map { Fmt.n($0.0) + "cm" })
            }
        }.padding(.vertical, 6)
    }
}

struct Avatar: View {
    let child: Child; var size: CGFloat = 40
    var body: some View {
        Circle().fill(Theme.color(child.colorIndex).gradient).frame(width: size, height: size)
            .overlay(Text(String(child.name.prefix(1))).font(.system(size: size * 0.45, weight: .bold)).foregroundStyle(.white))
    }
}

struct Pill: View {
    let title: String; let value: String?
    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value ?? "—").font(.subheadline.bold()).monospacedDigit()
        }.frame(maxWidth: .infinity).padding(.vertical, 6)
        .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct StatTile: View {
    let title: String; let icon: String; let value: String?; let date: Date?; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(color)
            Text(value ?? "—").font(.title2.bold()).monospacedDigit()
            Text(date.map { Fmt.date.string(from: $0) } ?? "未記録").font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ChildDetailView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var purchase: Purchase
    let childID: UUID
    @State private var record: SizeRecord? = Showcase.scene == "record" ? Showcase.sample()[0].sorted.last : nil
    @State private var note: BrandNote?
    @State private var editChild: Child?
    @State private var paywall = false

    var body: some View {
        if let i = store.index(childID) {
            let c = store.children[i]
            List {
                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatTile(title: "身長", icon: "ruler", value: c.latest(\.height).map { Fmt.n($0.0) + " cm" }, date: c.latest(\.height)?.1, color: Theme.color(0))
                        StatTile(title: "体重", icon: "scalemass", value: c.latest(\.weight).map { Fmt.n($0.0) + " kg" }, date: c.latest(\.weight)?.1, color: Theme.color(1))
                        StatTile(title: "服サイズ", icon: "tshirt", value: c.latest(\.clothing).map { "\($0.0)" }, date: c.latest(\.clothing)?.1, color: Theme.color(2))
                        StatTile(title: "靴サイズ", icon: "shoeprints.fill", value: c.latest(\.shoe).map { Fmt.n($0.0) + " cm" }, date: c.latest(\.shoe)?.1, color: Theme.color(3))
                    }.listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
                Section {
                    if Showcase.scene == "brand" {
                        brandRows(c, i)
                    } else {
                        recordRows(c, i)
                    }
                } header: {
                    HStack {
                        Text(Showcase.scene == "brand" ? "ブランド別サイズメモ" : "記録")
                        Spacer()
                        Button { addRecord() } label: { Label("記録する", systemImage: "plus.circle.fill") }.font(.subheadline)
                    }
                }
                if Showcase.scene != "brand" {
                    Section {
                        if purchase.unlocked { brandRows(c, i) } else {
                            Button { paywall = true } label: { Label("ブランド別のサイズメモ（全機能版）", systemImage: "lock.fill") }
                        }
                        Button { if purchase.unlocked { note = BrandNote() } else { paywall = true } } label: { Label("メモを追加", systemImage: "plus") }
                    } header: { Text("ブランド別サイズメモ") }
                }
            }
            .navigationTitle(c.name)
            .toolbar { Button("編集") { editChild = c } }
            .sheet(item: $record) { r in RecordEditView(childID: childID, record: r) }
            .sheet(item: $note) { n in BrandNoteEditView(childID: childID, note: n) }
            .sheet(item: $editChild) { ChildEditView(child: $0) }
            .sheet(isPresented: $paywall) { PaywallView() }
        } else { Text("見つかりません") }
    }

    @ViewBuilder func recordRows(_ c: Child, _ i: Int) -> some View {
        if c.records.isEmpty { Text("まだ記録がありません").foregroundStyle(.secondary) }
        ForEach(c.records.sorted { $0.date > $1.date }) { r in
            Button { record = r } label: { RecordRow(r: r) }.foregroundStyle(.primary)
        }.onDelete { idx in
            let list = c.records.sorted { $0.date > $1.date }
            let ids = Set(idx.map { list[$0].id })
            store.children[i].records.removeAll { ids.contains($0.id) }
        }
    }
    @ViewBuilder func brandRows(_ c: Child, _ i: Int) -> some View {
        ForEach(c.brandNotes) { n in
            Button { note = n } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(n.brand).font(.headline)
                        Text(n.category + (n.memo.isEmpty ? "" : "・" + n.memo)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(n.size).font(.title3.bold()).foregroundStyle(Theme.accent)
                }
            }.foregroundStyle(.primary)
        }.onDelete { store.children[i].brandNotes.remove(atOffsets: $0) }
    }
    func addRecord() {
        if store.canAddRecord(purchase.unlocked) {
            var r = SizeRecord()
            if let i = store.index(childID), let last = store.children[i].sorted.last { r.clothing = last.clothing; r.shoe = last.shoe }
            record = r
        } else { paywall = true }
    }
}

struct RecordRow: View {
    let r: SizeRecord
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Fmt.date.string(from: r.date)).font(.subheadline.bold())
            HStack(spacing: 12) {
                if let v = r.height { Text("身長 \(Fmt.n(v))cm") }
                if let v = r.weight { Text("体重 \(Fmt.n(v))kg") }
                if let v = r.foot { Text("足 \(Fmt.n(v))cm") }
            }.font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                if let v = r.clothing { Text("服 \(v)") }
                if let v = r.shoe { Text("靴 \(Fmt.n(v))cm") }
                if !r.memo.isEmpty { Text(r.memo).lineLimit(1) }
            }.font(.caption).foregroundStyle(.secondary)
        }
    }
}
