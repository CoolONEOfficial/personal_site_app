//
//  String+path.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.08.2021.
//

import Foundation

extension String {
    var filename: String {
        components(separatedBy: "/").last ?? self
    }
}
