//
//  PutItemRequest.swift
//  PersonalSiteApp_macos
//
//  Created by Nickolay Truhin on 09.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation

struct PutItemRequest: Encodable {
    var message: String
    let content: Data
    let sha: String?
}

extension PutItemRequest {
    init(from item: ContentItem, content: Data) {
        self.init(message: "Replace \(item.path.filename)", content: content, sha: item.sha)
    }
}
