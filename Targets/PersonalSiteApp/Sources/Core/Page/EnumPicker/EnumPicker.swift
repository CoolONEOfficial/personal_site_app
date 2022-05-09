//
//  EnumPicker.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 10.07.2021.
//

import Foundation
import SwiftUI

struct EnumPicker<Selectable: Identifiable & Hashable>: View {
    let title: String
    let options: [Selectable]
    let optionToString: (Selectable) -> String
    let stringToOption: (String) -> Selectable?

    @Binding var selected: Selectable

    var body: some View {
        Picker(title, selection: .init(
                get: { optionToString(selected) },
                set: { selected = stringToOption($0)! }
        )) {
            ForEach(options) {
                Text(optionToString($0))
            }
        }
    }
}
