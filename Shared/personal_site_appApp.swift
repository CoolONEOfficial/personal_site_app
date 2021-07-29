//
//  personal_site_appApp.swift
//  Shared
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import SwiftUI

@main
struct personal_site_appApp: App {
    var body: some Scene {
        WindowGroup {
            MainView<MainViewModel>(viewModel: MainViewModel())
        }
    }
}
