//
//  AuthService.swift
//  PersonalSiteApp_ios
//
//  Created by Nickolay Truhin on 10.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation
import OAuthSwift

protocol AuthServicing {
    func authorizeIfNeeded() async -> Result<Void, OAuthSwiftError>
}

class AuthService {
    let oauthswift = OAuth2Swift(
        consumerKey:    "1866ea61c6c8e65055e8",
        consumerSecret: try! Configuration.value(for: .consumerSecret),
        authorizeUrl:   "https://github.com/login/oauth/authorize",
        accessTokenUrl: "https://github.com/login/oauth/access_token",
        responseType:   "code"
    )
    
    var keychainService: KeychainServicing = KeychainService()
}

extension AuthService: AuthServicing {
    func authorizeIfNeeded() async -> Result<Void, OAuthSwiftError> {
        if let credential = keychainService.credential, credential.tokensValid {
            if credential.isTokenExpired() {
                return await withCheckedContinuation { continuation in
                    oauthswift.renewAccessToken(
                        withRefreshToken: credential.oauthRefreshToken,
                        parameters: nil, headers: nil
                    ) { [self] result in
                        continuation.resume(returning: handleAuthResult(result))
                    }
                }
            } else {
                // no-op
                return .success(Void())
            }
        } else {
            // oauthswift.authorizeURLHandler = getURLHandler()//TODO: internal auth
            let state = generateState(withLength: 20)
            return await withCheckedContinuation { continuation in
                oauthswift.authorize(
                    withCallbackURL: URL(string: "personal-site-app://oauth-callback/github")!,
                    scope: "user,repo", state: state
                ) { [self] result in
                    continuation.resume(returning: handleAuthResult(result))
                }
            }
        }
    }
}

private extension AuthService {
    func handleAuthResult(_ result: Result<OAuthSwift.TokenSuccess, OAuthSwiftError>) -> Result<Void, OAuthSwiftError> {
        switch result {
        case .success(let (credential, _, _)):
            debugPrint("SUCCESS \(credential)")
            
            self.keychainService.credential = credential
            
            return .success(Void())
            
        case .failure(let error):
            debugPrint("ERROR" + error.description)
            return .failure(error)
        }
    }
    
//    func getURLHandler() -> OAuthSwiftURLHandlerType {
//        ASWebAuthenticationURLHandler(
//            callbackUrlScheme: "personal-site-app",
//            presentationContextProvider: nil  // If the app doesn't support for multiple windows, it doesn't matter to use nil.
//        )
//    }
}

private extension OAuthSwiftCredential {
    var tokensValid: Bool {
        !oauthToken.isEmpty && (isTokenExpired() ? !oauthRefreshToken.isEmpty : true)
    }
}
