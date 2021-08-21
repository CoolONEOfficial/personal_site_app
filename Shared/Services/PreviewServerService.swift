//
//  PreviewServerService.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 07.08.2021.
//

import Foundation
import GCDWebServers

protocol PreviewServerServicing {
    func start(path: String)
    func stop()
    var serverUrl: URL? { get }
}

class PreviewServerService: PreviewServerServicing {
    static let `default` = PreviewServerService()
    private init() {}
    
    private var server: GCDWebServer?

    var serverUrl: URL? {
        server?.serverURL
    }
    
    func start(path: String) {
        stop()
        server = GCDWebServer()
        let path = "/" + path.trimmingCharacters(in: .init([ .init(unicodeScalarLiteral: "/") ])) + "/"
        server?.addGETHandler(forBasePath: "/", directoryPath: path, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
        server?.start()
    }

    func stop() {
        guard server?.isRunning == true else { return }
        server?.stop()
    }
}
