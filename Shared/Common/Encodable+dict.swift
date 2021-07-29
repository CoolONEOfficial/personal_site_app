//
//  MarkdownMetadataEncoder.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 15.07.2021.
//

import Foundation

extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(DateFormatter.metadata)
    let data = try encoder.encode(self)
    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
      throw NSError()
    }
    return dictionary
  }
}
