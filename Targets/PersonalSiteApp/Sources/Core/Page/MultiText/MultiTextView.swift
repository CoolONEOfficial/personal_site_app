//
//  MultiTextView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 10.07.2021.
//

import SwiftUI

struct MultiTextView<Selectable: Identifiable & Hashable>: View {
    let options: [Selectable]
    let optionToString: (Selectable) -> String

    @Binding var selected: [Selectable: String]
    
    var body: some View {
        List {
            ForEach(options) { selectable in
                HStack() {
                    Text(optionToString(selectable)).foregroundColor(.black).frame(minWidth: 0, maxWidth: .infinity)
                    TextField(
                        "Url",
                        text: .init(
                            get: { selected[selectable] ?? "" },
                            set: { str in
                                if str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    selected.removeValue(forKey: selectable)
                                } else {
                                    selected[selectable] = str
                                }
                            }
                        )
                    ).frame(minWidth: 0, maxWidth: .infinity)
                }
            }
        }
        .listStyle(listStyle)
    }

    private var listStyle: some ListStyle {
        #if os(iOS)
        GroupedListStyle()
        #else
        PlainListStyle()
        #endif
    }
    
//    private func toggleSelection(selectable: Selectable) {
//        if let existingIndex = selected.firstIndex(where: { $0.id == selectable.id }) {
//            selected.remove(at: existingIndex)
//        } else {
//            selected[]
//            selected.insert(selectable)
//        }
//    }
}

//struct MultiTextView_Previews: PreviewProvider {
//    static var previews: some View {
//        MultiTextView()
//    }
//}
