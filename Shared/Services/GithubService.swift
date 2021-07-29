//
//  GithubService.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import Foundation
import Alamofire
import Ink

struct PageMetadata: Codable {
    var description: String
    var date: Date
    
    var project: ProjectMetadata?
    var event: EventMetadata?
    var career: CareerMetadata?
    var book: BookMetadata?
    var achievement: AchievementMetadata?
    
    var type: ContentType? {
        if project != nil {
            return .projects
        } else if event != nil {
            return .events
        } else if career != nil {
            return .career
        } else if book != nil {
            return .books
        } else if achievement != nil {
            return .achievements
        }
        return nil
    }
    
    var tags: [String]?
    var videos: [String]?
    var logo: String?
    var singleImage: String?
    var endDate: Date?

    func logoUrl(filename: String) -> URL? {
        url(filename, "logo", logo)
    }
    
    func singleImageUrl(filename: String) -> URL? {
        url(filename, "singleImage", singleImage)
    }
    
    private func url(_ pagename: String, _ filename: String, _ ext: String?) -> URL? {
        guard let type = type, let ext = ext else { return nil }
        return GithubService.rawUrl("Resources/img/\(type.rawValue)/\(pagename.withoutExt)/\(filename)\(ext)")
    }
}

extension DateFormatter {
    static let metadata: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = .current
        return dateFormatter
    }()
}

class Page: ObservableObject {
    @Published var metadata: PageMetadata
    @Published var content: String
    @Published var title: String?

    init(from string: String) throws {
        let markdown = MarkdownParser().parse(string)
        let decoder = MarkdownMetadataDecoder(metadata: markdown.metadata, dateFormatter: DateFormatter.metadata)
        self.metadata = try PageMetadata(from: decoder)
        self.content = .init(string[string.index(string.indices(of: "---")[1], offsetBy: 4) ..< string.endIndex])
        self.title = markdown.title
    }

    func string() -> String? {
        guard let metadata = try? metadata.asDictionary().markdownEncoded() else { return nil }
        return """
            ---
            \(metadata)
            ---
            \(content)
            """
    }
}

extension Dictionary where Key == String {
    func markdownEncoded(prefix: [String] = []) -> String {
        map { (key, value) in
            var str = "\((prefix + [key]).joined(separator: ".")): "
            switch value {
            case let arr as Array<CustomStringConvertible>:
                str.append(arr.map(\.description).joined(separator: ", "))
            
            case let dict as Dictionary:
                return dict.markdownEncoded(prefix: prefix + [key])

            case let conv as CustomStringConvertible:
                str.append(conv.description)

            default:
                fatalError()
            }
            return str
        }.sorted().joined(separator: "\n")
    }
}

protocol GithubServicing {
    func fetchList(of type: ContentType, completion: @escaping (Result<[ContentItem], Error>) -> Void)
    func fetchItem(item: ContentItem, completion: @escaping (Result<Page, Error>) -> Void)
    func putItem(request: PutItemRequest, path: String, completion: @escaping (Result<Void, Error>) -> Void)
    func putItem(item: ContentItem, content: String, completion: @escaping (Result<Void, Error>) -> Void)
}

struct ContentItem: Codable, Hashable, Identifiable {
    var id: String { path }
    let name: String
    let path: String
    let sha: String?
    let size: UInt
    let downloadUrl: String
}

struct PutItemResponse: Codable {
    let content: ContentItem
}

struct PutItemRequest: Encodable {
    var message: String = "Update content"
    let content: String
    let sha: String?
}

extension PutItemRequest {
    init(from item: ContentItem, content: String) {
        self.init(content: content, sha: item.sha)
    }
}

class GithubService: GithubServicing {
    static let apiBase = "https://api.github.com"
    static let base = "https://github.com"
    
    private let headers = HTTPHeaders([ .accept("application/vnd.github.v3+json"), .authorization(Config.token) ])
    
    static let repo = "CoolONEOfficial/personal_site"

    static let repoUrl = base + "/" + repo
    
    static func rawUrl(_ path: String) -> URL? {
        .init(string: "\(repoUrl)/raw/master/\(path)")
    }
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func fetchList(of type: ContentType, completion: @escaping (Result<[ContentItem], Error>) -> Void) {
        AF.request("\(Self.apiBase)/repos/\(Self.repo)/contents/Content/\(type)", method: .get, headers: headers)
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

    func putItem(request: PutItemRequest, path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AF.request("\(Self.apiBase)/repos/\(Self.repo)/contents/\(path)", method: .put, parameters: request, encoder: JSONParameterEncoder.default, headers: headers)
            .responseDecodable(of: PutItemResponse.self, decoder: decoder) { completion($0.result.mapError { $0 as Error }.map {_ in ()}) }
    }

    func putItem(item: ContentItem, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        putItem(request: .init(from: item, content: content), path: item.path, completion: completion)
    }
}
