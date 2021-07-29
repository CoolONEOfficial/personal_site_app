//
//  Image.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 16.07.2021.
//

import SwiftUI

#if os(iOS)
import UIKit
typealias Image = UIImage

extension ImageView {
    init(image: Image) {
        self.init(uiImage: image)
    }
}
#else
import AppKit
typealias Image = NSImage

extension ImageView {
    init(image: Image) {
        self.init(nsImage: image)
    }
}
extension Image {
    convenience init?(systemName: String) {
        self.init(systemSymbolName: systemName, accessibilityDescription: nil)
    }
    
    func withTintColor(_ tintColor: NSColor) -> NSImage {
        if self.isTemplate == false {
            return self
        }
        let image = self.copy() as! NSImage
                image.lockFocus()
                tintColor.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
                imageRect.fill(using: .sourceIn)
                image.unlockFocus()
                image.isTemplate = false
        return image
    }
}
#endif

typealias ImageView = SwiftUI.Image
