import SwiftUI

struct ShoppingView: View {
    @State private var items: [String] = []
    @State private var newItem: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
                .onDelete { idx in items.remove(atOffsets: idx) }
            }
            .navigationTitle("Покупки")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        TextField("Добавить в список", text: $newItem)
                            .textFieldStyle(.roundedBorder)
                        Button("Добавить") {
                            let value = newItem.trimmingCharacters(in: .whitespaces)
                            guard !value.isEmpty else { return }
                            items.append(value)
                            newItem = ""
                        }
                    }
                }
            }
        }
    }
}

