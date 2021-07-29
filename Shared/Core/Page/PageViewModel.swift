//
//  PageViewModel.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//

import Foundation

enum Tab: Equatable {
    case editor
    case metadata
    case preview
}

enum PageViewState {
    case page(Page)
    case error(Error)
    case loading

    mutating func updatePage(completion: (Page) -> Void) {
        guard case let .page(page) = self else { return }
        completion(page)
        self = .page(page)
    }
}

protocol PageViewModeling: ObservableObject {
    var state: PageViewState { get set }
    var tab: Tab { get set }
    var isNewPage: Bool { get }
    var attachedImages: [String: Image] { get set }
    var logo: ImageOrUrl? { get set }
    var singleImage: ImageOrUrl? { get set }
    func updateView()
    func apply(filename: String?, dismissCompletion: @escaping () -> Void)
    func onAppear()
}

class PageViewModel: PageViewModeling {
    private let githubService: GithubServicing = GithubService()

    @Published var state: PageViewState = .loading
    @Published var tab: Tab = .editor
    @Published var attachedImages = [String: Image]()
    @Published var logo: ImageOrUrl?
    @Published var singleImage: ImageOrUrl?
    
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
//            guard let self = self else {
//                debugPrint("WTH!?")
//                return
//            }
            switch result {
            case let .success(page):
                self.state = .page(page)
                
                if let url = page.metadata.logoUrl(filename: item.name) {
                    logo = .url(url)
                } else {
                    logo = nil
                }
                
                if let url = page.metadata.singleImageUrl(filename: item.name) {
                    singleImage = .url(url)
                } else {
                    singleImage = nil
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

    func apply(filename: String?, dismissCompletion: @escaping () -> Void) {
        guard case let .page(page) = state,
              let content = page.string() else { return }

        defer { state = .loading }
        
        switch itemOrType {
        case let .item(item):
            githubService.putItem(item: item, content: content, completion: { self.putCompleted($0, dismissCompletion) })
        case let .type(type):
            guard let filename = filename else { fatalError() }
            githubService.putItem(request: .init(content: content, sha: nil), path: "\(type.rawValue)/\(filename)", completion: { self.putCompleted($0, dismissCompletion) })
        }
    }
    
    func putCompleted(_ result: Result<Void, Error>, _ dismissCompletion: () -> Void) {
        
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
