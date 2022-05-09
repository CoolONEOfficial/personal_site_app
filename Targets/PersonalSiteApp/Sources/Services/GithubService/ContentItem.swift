//
//  ContentItem.swift
//  PersonalSiteApp_macos
//
//  Created by Nickolay Truhin on 09.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation

struct ContentItem: Codable, Hashable, Identifiable {
    enum ItemType: String, Codable {
        case dir
        case file
        case symlink
        case submodule
    }
    
    var id: String { path }
    let type: ItemType
    let name: String
    let path: String
    let sha: String?
    let size: UInt
    let downloadUrl: String
}
