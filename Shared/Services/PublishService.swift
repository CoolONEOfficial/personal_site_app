import Foundation
////
////  PublishService.swift
////  personal_site_app
////
////  Created by Nickolay Truhin on 07.08.2021.
////
//
//import Foundation
//import Publish
//
//protocol PublishServicing {
//    func generate(url: URL, completion: @escaping (Result<URL, Error>) -> Void)
//}
//
//class PublishService: PublishServicing {
//    func generate(url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                let outputUrl = url.appendingPathComponent("Output")
//                let fm = FileManager.default
//                try? fm.removeItem(at: outputUrl)
//                try fm.createDirectory(at: outputUrl, withIntermediateDirectories: true, attributes: nil)
//
//                let resUrl = url.appendingPathComponent("Resources")
//                try fm.copyDirectoryContents(at: resUrl, to: outputUrl)
//
//                try PortfolioSite().publish(
//                    withTheme: Theme<PortfolioSite>(
//                        htmlFactory: PortfolioHTMLFactory(),
//                        resourcePaths: []
//                    ),
//                    at: Publish.Path(url.path),
//                    plugins: [
//                        .splash(withClassPrefix: ""),
//                        .darkImage(),
//                        .tinySlider(jsPath: "/modules/tiny-slider/src/tiny-slider.js", defaultConfig: [
//                            "mouseDrag": true,
//                            "swipeAngle": false,
//                            "controls": false,
//                            "nav": false,
//                            "loop": false,
//                            "lazyload": true,
//                            "responsive": [
//                                "350": [
//                                    "items": 2
//                                ],
//                                "500": [
//                                    "items": 3
//                                ]
//                            ],
//                        ])
//                    ]
//                )
//
//                try fm.copyDirectoryContents(at: outputUrl.appendingPathComponent("css"), to: outputUrl)
//
//                completion(.success(outputUrl))
//            } catch {
//                completion(.failure(error))
//                return
//            }
//        }
//    }
//}
//

