//
//  Image+pngData.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 09.05.2022.
//

#if os(macOS)
import AppKit
import Foundation

extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
extension NSImage {
    func pngData() -> Data? { tiffRepresentation?.bitmap?.png }
}
#endif
