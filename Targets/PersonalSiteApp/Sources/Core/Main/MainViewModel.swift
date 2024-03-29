//
//  MainViewModel.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import Foundation

enum MainViewState {
    typealias Items = [ContentType: [ContentItem]]
    
    case items(_ items: Items)
    case error(Error)
    
    var items: Items? {
        get {
            if case let .items(items) = self { return items }
            return nil
        }
        set {
            guard let newValue = newValue else { return }
            self = .items(newValue)
        }
    }
    
    mutating func updateItems(completion: (inout Items) -> Void) {
        guard var items = self.items else { return }
        completion(&items)
        self.items = items
    }
}

protocol MainViewModeling: ObservableObject {
    var state: MainViewState { get set }
    var isLoading: Bool { get set }
    func onFirstAppear() async
    func refreshContent()
    func onDelete(items: [ContentItem])
    func deleteCompletion(confirm: Bool, deletedItems: [ContentItem], oldItems: MainViewState.Items?)
}

class MainViewModel: MainViewModeling {
    private let githubService: GithubServicing = GithubService()
    private let authService: AuthServicing = AuthService()

    @Published var state: MainViewState = .items(.init())
    @Published var isLoading = false

    func deleteCompletion(confirm: Bool, deletedItems: [ContentItem], oldItems: MainViewState.Items?) {
        if confirm {
            onDelete(items: deletedItems)
        } else {
            state.items = oldItems
        }
    }

    @MainActor
    func onFirstAppear() async {
        switch await authService.authorizeIfNeeded() {
        case .success:
            refreshContent()
            
        case let .failure(error):
            state = .error(error)
        }
    }
    
    func refreshContent() {
        isLoading = true
        let group = DispatchGroup()
        
        var errors = [Error]()
        
        var items = [ContentType: [ContentItem]].init(uniqueKeysWithValues: ContentType.allCases.map { ($0, []) })
        
        for type in ContentType.allCases {
            group.enter()
            githubService.fetchContentsList(of: type, pagename: nil) { result in
                defer { group.leave() }
                switch result {
                case let .success(_items):
                    items[type] = _items

                case let .failure(error):
                    errors.append(error)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if errors.count == ContentType.allCases.count, let error = errors.first {
                self.state = .error(error)
            } else {
                self.state = .items(items)
            }
            self.isLoading = false
        }
    }
    
    func onDelete(items: [ContentItem]) {
        isLoading = true
        
        let group = DispatchGroup()
        
        for item in items {
            group.enter()
            githubService.deleteItem(item: item) { _ in group.leave() }
        }
        
        group.notify(queue: .main) { [self] in isLoading = false }
    }
}
