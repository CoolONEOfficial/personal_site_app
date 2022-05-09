//
//  DateFormatter+metadata.swift
//  PersonalSiteApp_macos
//
//  Created by Nickolay Truhin on 09.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation

public extension DateFormatter {
    static let metadata: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = .current
        return dateFormatter
    }()
}
