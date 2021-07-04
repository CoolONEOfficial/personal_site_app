//
//  MainViewModel.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import Foundation

protocol MainViewModeling: ObservableObject {
    var items: [ContentType: [ContentItem]] { get set }
    var error: Error? { get set }
    var isLoading: Bool { get set }
    
    func viewAppear()
}

class MainViewModel: MainViewModeling {
    private let githubService: GithubServicing = GithubService()
    
    @Published var items = [ContentType: [ContentItem]].init(uniqueKeysWithValues: ContentType.allCases.map { ($0, []) })
    @Published var isLoading = false
    @Published var error: Error? = nil

    func viewAppear() {
        isLoading = true
        
        let group = DispatchGroup()
        
        var errors = [Error]()
        
        for type in ContentType.allCases {
            group.enter()
            githubService.fetchList(of: type) { [weak self] result in
                defer { group.leave() }
                guard let self = self else { return }
                switch result {
                case let .success(items):
                    self.items[type] = items

                case let .failure(error):
                    errors.append(error)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            if errors.count == ContentType.allCases.count {
                self.error = errors.first
            }
        }
    }
}
