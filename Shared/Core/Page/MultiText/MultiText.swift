//
//  MultiText.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 12.07.2021.
//

import Foundation
import SwiftUI

struct MultiText<LabelView: View, Selectable: Identifiable & Hashable>: View {
    let label: LabelView
    let options: [Selectable]
    let optionToString: (Selectable) -> String

    @Binding var selected: [Selectable: String]

    private var formattedSelectedListString: String {
        ListFormatter.localizedString(byJoining: selected.map { optionToString($0.key) })
    }

    var body: some View {
        NavigationLink(destination: multiTextView()) {
            HStack {
                label
                Spacer()
                Text(formattedSelectedListString)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func multiTextView() -> some View {
        MultiTextView(
            options: options,
            optionToString: optionToString,
            selected: $selected
        )
    }
}
