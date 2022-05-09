//
//  ListText.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 15.07.2021.
//

import Foundation
import SwiftUI

struct ListText: View {
    let title: String
    @Binding var text: [String]?
    
    var body: some View {
        TextField(title, text: .init(
            get: { text?.joined(separator: ",") ?? "" },
            set: { text = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
        ))
    }
}
