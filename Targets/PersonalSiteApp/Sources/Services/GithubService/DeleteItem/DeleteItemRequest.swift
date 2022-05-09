//
//  DeleteItemRequest.swift
//  PersonalSiteApp_macos
//
//  Created by Nickolay Truhin on 09.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation

struct DeleteItemRequest: Encodable {
    var message: String
    let sha: String?
}
