//
//  String++.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.08.2021.
//

import Foundation

extension String {
    var filename: String {
        components(separatedBy: "/").last ?? self
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    var withoutExt: String {
        String(self[startIndex ..< (firstIndex(of: ".") ?? endIndex)])
    }
}
