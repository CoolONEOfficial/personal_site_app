//
//  Configuration.swift
//  PersonalSiteApp_ios
//
//  Created by Nickolay Truhin on 11.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation

enum Configuration {
    enum Key: String {
        case consumerSecret = "CONSUMER_SECRET"
    }
    
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: Key) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key.rawValue) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}
