//
//  PageViewModel.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//

import Foundation

protocol PageViewModeling: ObservableObject {
    var error: Error? { get set }
    var isLoading: Bool { get set }
    var page: Page? { get set }
    var editor: Bool { get set }
    func updateView()
}

class PageViewModel: PageViewModeling {
    private let githubService: GithubServicing = GithubService()

    @Published var isLoading = false
    @Published var error: Error? = nil
    @Published var page: Page? = nil
    @Published var editor: Bool = true
    
    func updateView() {
        self.objectWillChange.send()
    }
    
    init(item: ContentItem) {
        isLoading = true
        githubService.fetchItem(item: item) { [weak self] result in
            guard let self = self else { return }
            defer { self.isLoading = false }
            switch result {
            case let .success(page):
                self.page = page

            case let .failure(error):
                self.error = error
            }
        }
    }
}
