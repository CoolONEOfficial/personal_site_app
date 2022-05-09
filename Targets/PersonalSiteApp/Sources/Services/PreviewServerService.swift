//
//  PreviewServerService.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 07.08.2021.
//

import Foundation
import Telegraph

protocol PreviewServerServicing {
    func start(path: String)
    func stop()
    var serverUrl: URL? { get }
}

class PreviewServerService: PreviewServerServicing {
    static let `default` = PreviewServerService()
    private init() {}
    
    private var server: Server?

    var serverUrl: URL? {
        .init(string: "http://localhost:\(server!.port)")
    }
    
    func start(path: String) {
        stop()
        server = .init()
        let path = "/" + path.trimmingCharacters(in: .init([ .init(unicodeScalarLiteral: "/") ])) + "/"
        server?.serveDirectory(.init(fileURLWithPath: path))
        try! server?.start(port: 0, interface: "localhost")
    }

    func stop() {
        guard server?.isRunning == true else { return }
        server?.stop()
    }
}
