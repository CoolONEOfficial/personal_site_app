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
    
    func markdownPath(pagename: String) -> String {
        "Content/\(rawValue)/\(pagename).md"
    }
    
    func resourcesDirectoryPath(pagename: String) -> String? {
        path(pagename, nil, nil)
    }

    func url(_ pagename: String, _ filename: String, _ ext: String?) -> URL? {
        guard let path = path(pagename, filename, ext) else { return nil }
        return GithubService.rawUrl(path)
    }

    func path(_ pagename: String, _ filename: String?, _ ext: String?) -> String? {
        if filename != nil, ext == nil { return nil }
        return ["Resources", rawValue, pagename.withoutExt, filename != nil ? "\(filename ?? "")\(ext ?? "")" : nil].compactMap { $0 }.joined(separator: "/")
    }
}
