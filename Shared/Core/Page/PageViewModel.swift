//
//  PageViewModel.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//

import Foundation
import CryptoKit

enum Tab: Equatable {
    case editor
    case metadata
    case preview
}

enum PageViewState {
    case page(Page)
    case error(Error)
    case loading

    var page: Page? {
        get {
            if case let .page(page) = self { return page }
            return nil
        }
        set {
            guard let newValue = newValue else { return }
            self = .page(newValue)
        }
    }

    mutating func updatePage(completion: (Page) -> Void) {
        guard let page = self.page else { return }
        completion(page)
        self.page = page
    }
}

protocol PageViewModeling: ObservableObject {
    var state: PageViewState { get set }
    var tab: Tab { get set }
    var isNewPage: Bool { get }
    var attachedImages: Snapshot<[String: ImageOrUrl]> { get set }
    var logo: Snapshot<ImageOrUrl?> { get set }
    var singleImage: Snapshot<ImageOrUrl?> { get set }
    func updateView()
    func apply(filename: String, dismissCompletion: @escaping () -> Void)
    func onAppear()
}

class PageViewModel: PageViewModeling {
    private let githubService: GithubServicing = GithubService()

    @Published var state: PageViewState = .loading
    @Published var tab: Tab = .editor
    @Published var attachedImages = Snapshot([String: ImageOrUrl]())
    @Published var logo: Snapshot<ImageOrUrl?> = .init(nil)
    @Published var singleImage: Snapshot<ImageOrUrl?> = .init(nil)
    
    enum ItemOrType {
        case item(ContentItem)
        case type(ContentType)
    }
    private let itemOrType: ItemOrType

    var isNewPage: Bool {
        if case .type = itemOrType {
            return true
        }
        return false
    }
    
    init(item: ContentItem) {
        self.itemOrType = .item(item)
    }

    func onAppear() {
        guard case let .item(item) = itemOrType else { return }
        githubService.fetchItem(item: item) { [self] result in
            switch result {
            case let .success(page):
                self.state = .page(page)
                
                if let url = page.metadata.logoUrl(pagename: item.name),
                   let path = page.metadata.logoPath(pagename: item.name) {
                    logo = .init(.remote(path, url))
                } else {
                    logo = .init(nil)
                }

                if let url = page.metadata.singleImageUrl(pagename: item.name),
                   let path = page.metadata.singleImagePath(pagename: item.name) {
                    singleImage = .init(.remote(path, url))
                } else {
                    singleImage = .init(nil)
                
                }

            case let .failure(error):
                self.state = .error(error)
            }
        }
    }
    
    init(type: ContentType) {
        let page = try! Page(from: """
            ---
            date: 2021-01-01 00:00
            description: Description
            ---
            # Title

            Description
            
            """)
        
        switch type {
        case .projects:
            page.metadata.project = .new
        case .books:
            page.metadata.book = .new
        case .events:
            page.metadata.event = .new
        case .career:
            page.metadata.career = .new
        case .achievements:
            page.metadata.achievement = .new
        }
        
        state = .page(page)
        itemOrType = .type(type)
    }
    
    func updateView() {
        self.objectWillChange.send()
    }

    func apply(filename: String, dismissCompletion: @escaping () -> Void) {
        guard let page = state.page,
              let content = page.string()?.data(using: .utf8)?.base64EncodedData() else { return }

        defer { state = .loading }
        
        let group = DispatchGroup()
        
        group.enter()
        switch itemOrType {
        case let .item(item):
            githubService.putItem(item: item, content: content) { _ in group.leave() }
        case let .type(type):
            githubService.putItem(request: .init(content: content, sha: nil), path: "\(type.rawValue)/\(filename)") { _ in group.leave() }
        }

        putImage(page: page, image: singleImage, filename: "singleImage", pagename: filename, ext: page.metadata.singleImage, group: group)
        putImage(page: page, image: logo, filename: "logo", pagename: filename, ext: page.metadata.logo, group: group)
    }

    func putImage(page: Page, image: Snapshot<ImageOrUrl?>, filename: String, pagename: String, ext: String?, group: DispatchGroup) {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            defer { group.leave() }
            
            guard let url = page.metadata.url(pagename, filename, ext),
                  let path = page.metadata.path(pagename, filename, ext) else { return }
            var sha: String?
            if let data = try? Data(contentsOf: url) {
                sha = SHA256.hash(data: data).hexStr
            } else {
                sha = nil
            }
            
            switch (image.original, image.value) {
            case let (.none, .image(image)), let (.remote, .image(image)):
                guard let imageData = image.pngData() else { return }

                group.enter()
                githubService.putItem(request: .init(content: imageData, sha: sha), path: path) { _ in group.leave() }

            case let (.remote(path, _), .none):
                group.enter()
                githubService.deleteItem(request: .init(sha: sha), path: path) { _ in group.leave() }
                
            default: break
            }
        }
    }
}

extension ProjectMetadata {
    static let new: Self = .init(type: .app, platforms: [])
}

extension BookMetadata {
    static let new: Self = .init(author: "", organisation: "")
}

extension EventMetadata {
    static let new: Self = .init(location: nil, place: nil, type: .course)
}

extension CareerMetadata {
    static let new: Self = .init(location: nil, type: .contract, position: "", achievements: [])
}

extension AchievementMetadata {
    static let new: Self = .init(type: .certificate)
}

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }

    var hexStr: String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }
}
