//
//  KeychainService.swift
//  PersonalSiteApp_ios
//
//  Created by Nickolay Truhin on 10.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation
import KeychainSwift
import OAuthSwift

protocol KeychainServicing {
    var credential: OAuthSwiftCredential? { get set }
}

class KeychainService {
    let keychain = KeychainSwift()
}

extension KeychainService: KeychainServicing {
    private enum Keys: String {
        case oauth_credential
    }
    
    var credential: OAuthSwiftCredential? {
        get {
            let res: OAuthSwiftCredential? = get(Keys.oauth_credential)
            debugPrint("res get \(res?.oauthTokenSecret)")
            return res
        }
        set {
            set(Keys.oauth_credential, newValue)
            debugPrint("res set \(newValue?.oauthTokenSecret)")
        }
    }
    
    private func get<T: Decodable>(_ key: Keys) -> T? {
        guard let data = keychain.getData(key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func set<T: Encodable>(_ key: Keys, _ value: T?) {
        if let value = value {
            let data = try! JSONEncoder().encode(value)
            keychain.set(data, forKey: key.rawValue, withAccess: nil)
        } else {
            keychain.delete(key.rawValue)
        }
    }
}
