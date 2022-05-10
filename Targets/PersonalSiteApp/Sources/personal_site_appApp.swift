//
//  personal_site_appApp.swift
//  Shared
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import SwiftUI
import OAuthSwift

@main
struct personal_site_appApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: MainViewModel()).onOpenURL { url in
                if url.host == "oauth-callback" {
                    OAuthSwift.handle(url: url)
                }
            }
        }
    }
}
