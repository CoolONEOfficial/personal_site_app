//
//  PreviewViewModel.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 07.08.2021.
//

import Foundation

enum PreviewViewState {
    case url(URL)
    case error(Error)
    case loading(LoadingStep, Double)
    
    enum LoadingStep {
        case download
        case unpack
        case generate
        
        var name: String {
            switch self {
            case .download:
                return "Downloading"
                
            case .unpack:
                return "Unpacking"
            
            case .generate:
                return "Generating"
            }
        }
    }
}

protocol PreviewViewModeling: ObservableObject {
    var state: PreviewViewState { get set }
    func onAppear()
    func onDisappear()
    func reloadRepo()
}

class PreviewViewModel: PreviewViewModeling {
    init(content: String, type: ContentType, pagename: String) {
        self.content = content
        self.type = type
        self.pagename = pagename
    }
    
    @Published var state: PreviewViewState = .loading(.download, 0)
    let content: String
    let type: ContentType
    let pagename: String
    
    private let githubService: GithubServicing = GithubService()
//    private let previewServerService: PreviewServerServicing = PreviewServerService.default
//    private let publishService: PublishServicing = PublishService()
    
    private lazy var docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private lazy var contentUrl = docUrl.appendingPathComponent("Content")
    
    private var appear: Bool = false
    private let fm = FileManager.default
    
    func onAppear() {
        guard !appear else { return }
        appear = true
        if (try? fm.contentsOfDirectory(at: docUrl, includingPropertiesForKeys: nil).count) ?? 0 == 0 {
            downloadRepo()
        } else {
            generatePreview()
        }
    }
    
    func onDisappear() {
       // previewServerService.stop()
    }
    
    func reloadRepo() {
        for item in (try? fm.contentsOfDirectory(at: docUrl, includingPropertiesForKeys: nil)) ?? [] {
            try? fm.removeItem(at: item)
        }
        downloadRepo()
    }
}

private extension PreviewViewModel {
    static func hasChanges(url: URL, content: String) -> Bool {
        (try? String(contentsOf: url).compare(content) == .orderedSame) ?? false
    }
    
    func downloadRepo() {
        githubService.downloadRepo(
            progressHandler: { [self] progress in
                state = .loading(.download, progress)
            }
        ) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(fileUrl):
                    guard let fileUrl = fileUrl else { fatalError() }
                    
                    unpackRepo(fileUrl: fileUrl)

                case let .failure(error):
                    state = .error(error)
                }
            }
        }
    }
    
    func unpackRepo(fileUrl: URL) {
        githubService.unpackRepo(
            progressHandler: { [self] progress in
                state = .loading(.unpack, progress)
            },
            from: fileUrl,
            to: docUrl
        ) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    do {
                        let markdownUrl = contentUrl.appendingPathComponent("\(type)/\(pagename).md")
                        try content.write(to: markdownUrl, atomically: true, encoding: .utf8)

                        generatePreview()
                    } catch {
                        state = .error(error)
                    }
                
                case let .failure(error):
                    state = .error(error)
                }
            }
        }
    }
    
    func generatePreview() {
//        publishService.generate(url: docUrl) { [self] result in
//            DispatchQueue.main.async {
//                switch result {
//                case let .success(outputUrl):
//                    startServer(outputUrl: outputUrl)
//
//                case let .failure(error):
//                    self.state = .error(error)
//                }
//            }
//        }
    }
    
    func startServer(outputUrl: URL) {
//        previewServerService.start(path: outputUrl.path)
//        if let url = previewServerService.serverUrl {
//            self.state = .url(url.appendingPathComponent(type.rawValue).appendingPathComponent(pagename).appendingPathComponent("index.html"))
//        }
    }
}
