//
//  GithubService.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import Foundation
import Alamofire
import Ink

struct PageMetadata: Decodable {
    var description: String
    var date: Date
    
    var project: ProjectMetadata?
    var event: EventMetadata?
    var career: CareerMetadata?
    var book: BookMetadata?
    var achievement: AchievementMetadata?
    
    var videos: [String]?
    var logo: String?
    var singleImage: String?
    var endDate: String?
}

class Page: ObservableObject {
    @Published var metadata: PageMetadata
    @Published var content: String
    @Published var title: String?

    init(from string: String) throws {
        let markdown = MarkdownParser().parse(string)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = .current
        let decoder = MarkdownMetadataDecoder(metadata: markdown.metadata, dateFormatter: dateFormatter)
        self.metadata = try PageMetadata(from: decoder)
        self.content = .init(string[string.index(string.indices(of: "---")[1], offsetBy: 4) ..< string.endIndex])
        self.title = markdown.title
    }
}

protocol GithubServicing {
    func fetchList(of type: ContentType, completion: @escaping (Result<[ContentItem], Error>) -> Void)
    func fetchItem(item: ContentItem, completion: @escaping (Result<Page, Error>) -> Void)
}

struct ContentItem: Codable, Hashable, Identifiable {
    var id: String { path }
    let name: String
    let path: String
    let sha: String
    let size: UInt
    let downloadUrl: String
}

class GithubService: GithubServicing {
    private let base = "https://api.github.com"
    
    private let headers = HTTPHeaders([ .accept("application/vnd.github.v3+json") ])
    
    private let repo = "CoolONEOfficial/personal_site"
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func fetchList(of type: ContentType, completion: @escaping (Result<[ContentItem], Error>) -> Void) {
        AF.request(base + "/repos/\(repo)/contents/Content/\(type)", method: .get, headers: headers)
            .responseDecodable(of: [ContentItem].self, decoder: decoder) { completion($0.result.mapError { $0 as Error }) }
    }

    func fetchItem(item: ContentItem, completion: @escaping (Result<Page, Error>) -> Void) {
        AF.request(item.downloadUrl, method: .get, headers: headers)
            .responseString {
                completion($0.tryMap {
                    try Page(from: $0)
                }.result)
            }
    
    }
}





