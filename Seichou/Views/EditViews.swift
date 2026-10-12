import SwiftUI

struct ChildEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State var child: Child
    @State private var hasBirthday = false
    var body: some View {
        NavigationStack {
            Form {
                TextField("名前・ニックネーム", text: $child.name)
                Toggle("誕生日を入れる", isOn: $hasBirthday)
                if hasBirthday {
                    DatePicker("誕生日", selection: Binding(get: { child.birthday ?? .now }, set: { child.birthday = $0 }), in: ...Date.now, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }
                Picker("色", selection: $child.colorIndex) {
                    ForEach(0..<Theme.childColors.count, id: \.self) { i in
                        Image(systemName: "circle.fill").foregroundStyle(Theme.color(i)).tag(i)
                    }
                }.pickerStyle(.segmented)
            }
            .navigationTitle(store.index(child.id) == nil ? "子どもを追加" : "子どもを編集")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { hasBirthday = child.birthday != nil }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var c = child; if !hasBirthday { c.birthday = nil }
                        c.name = c.name.trimmingCharacters(in: .whitespaces)
                        if let i = store.index(c.id) { store.children[i] = c } else { store.children.append(c) }
                        dismiss()
                    }.disabled(child.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct NumField: View {
    let title: String; let unit: String; @Binding var value: Double?
    @State private var text = ""
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", text: $text).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100)
                .onChange(of: text) { _, t in value = Double(t.replacingOccurrences(of: ",", with: ".")) }
            Text(unit).foregroundStyle(.secondary).frame(width: 30, alignment: .leading)
        }.onAppear { text = value.map { Fmt.n($0) } ?? "" }
    }
}

struct RecordEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let childID: UUID
    @State var record: SizeRecord
    static let clothingSizes = [50, 60, 70, 80, 90, 95, 100, 110, 120, 130, 140, 150, 160, 170]
    static let shoeSizes: [Double] = Array(stride(from: 10.0, through: 26.0, by: 0.5))
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("日付", selection: $record.date, displayedComponents: .date).environment(\.locale, Locale(identifier: "ja_JP"))
                Section("からだ") {
                    NumField(title: "身長", unit: "cm", value: $record.height)
                    NumField(title: "体重", unit: "kg", value: $record.weight)
                    NumField(title: "足の長さ", unit: "cm", value: $record.foot)
                }
                Section("いま着ているサイズ") {
                    Picker("服", selection: $record.clothing) {
                        Text("—").tag(Int?.none)
                        ForEach(Self.clothingSizes, id: \.self) { Text("\($0)").tag(Int?.some($0)) }
                    }
                    Picker("靴", selection: $record.shoe) {
                        Text("—").tag(Double?.none)
                        ForEach(Self.shoeSizes, id: \.self) { Text(Fmt.n($0) + " cm").tag(Double?.some($0)) }
                    }
                }
                Section("メモ") { TextField("例：保育園の身体測定", text: $record.memo, axis: .vertical) }
            }
            .navigationTitle("サイズを記録").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let i = store.index(childID) {
                            if let j = store.children[i].records.firstIndex(where: { $0.id == record.id }) { store.children[i].records[j] = record }
                            else { store.children[i].records.append(record) }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BrandNoteEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let childID: UUID
    @State var note: BrandNote
    var body: some View {
        NavigationStack {
            Form {
                TextField("ブランド・お店（例：ユニクロ）", text: $note.brand)
                Picker("種類", selection: $note.category) { ForEach(BrandNote.categories, id: \.self) { Text($0) } }
                TextField("ちょうどいいサイズ（例：110）", text: $note.size)
                TextField("メモ（例：袖が長め）", text: $note.memo, axis: .vertical)
            }
            .navigationTitle("ブランド別メモ").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let i = store.index(childID) {
                            if let j = store.children[i].brandNotes.firstIndex(where: { $0.id == note.id }) { store.children[i].brandNotes[j] = note }
                            else { store.children[i].brandNotes.append(note) }
                        }
                        dismiss()
                    }.disabled(note.brand.isEmpty || note.size.isEmpty)
                }
            }
        }
    }
}
