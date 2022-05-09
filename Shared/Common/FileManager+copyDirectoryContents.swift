//
//  FileManager+copyDirectoryContents.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 09.05.2022.
//

import Foundation

extension FileManager {
    func copyDirectoryContents(at dirUrl: URL, to destUrl: URL) throws {
        for url in try contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil) {
            try copyItem(at: url, to: destUrl.appendingPathComponent(url.lastPathComponent))
        }
    }
}
