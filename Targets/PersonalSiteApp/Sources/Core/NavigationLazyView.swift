//
//  NavigationLazyView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 22.08.2021.
//

import SwiftUI

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
