//
//  MainViewModel.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import Foundation

enum MainViewState {
    case items([ContentType: [ContentItem]])
    case error(Error)
    case loading
}

protocol MainViewModeling: ObservableObject {
    var state: MainViewState { get set }
    func onAppear()
}

class MainViewModel: MainViewModeling {
    private let githubService: GithubServicing = GithubService()

    @Published var state: MainViewState = .loading
    
    func onAppear() {
        let group = DispatchGroup()
        
        var errors = [Error]()
        
        var items = [ContentType: [ContentItem]].init(uniqueKeysWithValues: ContentType.allCases.map { ($0, []) })
        
        for type in ContentType.allCases {
            group.enter()
            githubService.fetchList(of: type) { result in
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
        }
    }
}
