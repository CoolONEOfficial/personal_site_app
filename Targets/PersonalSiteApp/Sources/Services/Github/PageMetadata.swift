//
//  PageMetadata.swift
//  PersonalSiteApp_macos
//
//  Created by Nickolay Truhin on 09.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation
import PortfolioSite

struct PageMetadata: Codable {
    var description: String
    var date: Date
    
    var project: ProjectMetadata?
    var event: EventMetadata?
    var career: CareerMetadata?
    var book: BookMetadata?
    var achievement: AchievementMetadata?
    
    var tags: [String]?
    var videos: [String]?
    var logo: String?
    var singleImage: String?
    var endDate: Date?
}

extension PageMetadata {
    
    var type: ContentType? {
        if project != nil {
            return .projects
        } else if event != nil {
            return .events
        } else if career != nil {
            return .career
        } else if book != nil {
            return .books
        } else if achievement != nil {
            return .achievements
        }
        return nil
    }
    
    func logoUrl(pagename: String) -> URL? {
        type?.url(pagename, "logo", logo)
    }
    
    func logoPath(pagename: String) -> String? {
        type?.path(pagename, "logo", logo)
    }
    
    func singleImageUrl(pagename: String) -> URL? {
        type?.url(pagename, "singleImage", singleImage)
    }

    func singleImagePath(pagename: String) -> String? {
        type?.path(pagename, "singleImage", singleImage)
    }
}
