//
//  ErrorView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            Image(systemName: "exclamationmark.triangle").resizable().frame(width: 100, height: 100)
            Text(error.asAFError?.errorDescription ?? error.localizedDescription).multilineTextAlignment(.center)
        }.padding(32)
    }
}
