//
//  Page.swift
//  PersonalSiteApp_macos
//
//  Created by Nickolay Truhin on 09.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation
import SwiftUI
import Ink

class Page: ObservableObject {
    @Published var metadata: PageMetadata
    @Published var content: String
    @Published var title: String?

    init(from string: String) throws {
        let markdown = Ink.MarkdownParser().parse(string)
        let decoder = MarkdownMetadataDecoder(metadata: markdown.metadata, dateFormatter: DateFormatter.metadata)
        self.metadata = try PageMetadata(from: decoder)
        self.content = .init(string[string.index(string.indices(of: "---")[1], offsetBy: 4) ..< string.endIndex])
        self.title = markdown.title
    }
}

extension Page {
    func string() -> String? {
        guard let metadata = try? metadata.asDictionary().markdownEncoded() else { return nil }
        return """
            ---
            \(metadata)
            ---
            \(content)
            """
    }
}

fileprivate extension Dictionary where Key == String {
    func markdownEncoded(prefix: [String] = []) -> String {
        map { (key, value) in
            var str = "\((prefix + [key]).joined(separator: ".")): "
            switch value {
            case let arr as Array<CustomStringConvertible>:
                str.append(arr.map(\.description).joined(separator: ", "))
            
            case let dict as Dictionary:
                return dict.markdownEncoded(prefix: prefix + [key])

            case let conv as CustomStringConvertible:
                str.append(conv.description)

            default:
                fatalError()
            }
            return str
        }.sorted().joined(separator: "\n")
    }
}
