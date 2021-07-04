//
//  ContentType.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//

import Foundation

enum ContentType: String, CaseIterable, Identifiable {
    case projects
    case books
    case events
    case career
    case achievements
    
    var id: RawValue { rawValue }

    var name: String {
        rawValue.capitalizingFirstLetter()
    }
}
