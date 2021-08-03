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

    func logoUrl(pagename: String) -> URL? {
        url(pagename, "logo", logo)
    }
    
    func logoPath(pagename: String) -> String? {
        path(pagename, "logo", logo)
    }
    
    func markdownPath(pagename: String) -> String? {
        guard let type = type else { return nil }
        return "Content/\(type.rawValue)/\(pagename).md"
    }
    
    func singleImageUrl(pagename: String) -> URL? {
        url(pagename, "singleImage", singleImage)
    }

    func singleImagePath(pagename: String) -> String? {
        path(pagename, "singleImage", singleImage)
    }
    
    func resourcesDirectoryPath(pagename: String) -> String? {
        path(pagename, nil, nil)
    }

    func url(_ pagename: String, _ filename: String, _ ext: String?) -> URL? {
        guard let path = path(pagename, filename, ext) else { return nil }
        return GithubService.rawUrl(path)
    }

    func path(_ pagename: String, _ filename: String?, _ ext: String?) -> String? {
        guard let type = type else { return nil }
        if filename != nil, ext == nil { return nil }
        return ["Resources", "img", type.rawValue, pagename.withoutExt, filename != nil ? "\(filename ?? "")\(ext ?? "")" : nil].compactMap { $0 }.joined(separator: "/")
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
    func fetchContentsList(of type: ContentType, pagename: String?, completion: @escaping (Result<[ContentItem], Error>) -> Void)
    func fetchItem(item: ContentItem, completion: @escaping (Result<Page, Error>) -> Void)
    func putItem(request: PutItemRequest, path: String, completion: @escaping (Result<Void, Error>) -> Void)
    func putItem(item: ContentItem, content: Data, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteItem(request: DeleteItemRequest, path: String, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteDirectory(message: String, path: String, completion: @escaping (Result<Void, Error>) -> Void)
}

struct ContentItem: Codable, Hashable, Identifiable {
    enum ItemType: String, Codable {
        case dir
        case file
        case symlink
        case submodule
    }
    
    var id: String { path }
    let type: ItemType
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
    let content: Data
    let sha: String?
}

struct DeleteItemRequest: Encodable {
    var message: String = "Delete content"
    let sha: String?
}

extension PutItemRequest {
    init(from item: ContentItem, content: Data) {
        self.init(content: content, sha: item.sha)
    }
}

class GithubService: GithubServicing {
    static let apiBase = "https://api.github.com"
    
    static let apiContentsBase = apiBase + "/repos/" + repo + "/contents"
    
    static let base = "https://github.com"
    
    private let headers = HTTPHeaders([ .accept("application/vnd.github.v3+json"), .authorization(Config.token) ])
    
    static let repo = "CoolONEOfficial/personal_site"

    static let repoUrl = base + "/" + repo
    
    static func rawUrl(_ path: String) -> URL? {
        .init(string: "\(repoUrl)/raw/master/\(path.trimmingCharacters(in: .init(arrayLiteral: .init(unicodeScalarLiteral: "/"))))")
    }
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    
    // MARK: Fetch
    
    func fetchContentsList(of type: ContentType, pagename: String? = nil, completion: @escaping (Result<[ContentItem], Error>) -> Void) {
        fetchList(of: type, folder: "Content", pagename: pagename, completion: completion)
    }

    func fetchResourcesList(of type: ContentType, pagename: String? = nil, completion: @escaping (Result<[ContentItem], Error>) -> Void) {
        fetchList(of: type, folder: "Resources/img", pagename: pagename, completion: completion)
    }

    func fetchList(of type: ContentType, folder: String, pagename: String? = nil, completion: @escaping (Result<[ContentItem], Error>) -> Void) {
        fetchList(path: [Self.apiContentsBase, folder, type.rawValue, pagename].compactMap { $0 }.joined(separator: "/"), completion: completion)
    }
    
    func fetchList(path: String, completion: @escaping (Result<[ContentItem], Error>) -> Void) {
        AF.request(path, method: .get, headers: headers)
            .responseDecodable(of: [ContentItem].self, decoder: decoder, completionHandler: makeCompletion(completion))
    }

    func fetchItem(item: ContentItem, completion: @escaping (Result<Page, Error>) -> Void) {
        AF.request(item.downloadUrl, method: .get, headers: headers)
            .responseString {
                completion($0.tryMap {
                    try Page(from: $0)
                }.result)
            }
    }

    // MARK: Put
    
    func putItem(request: PutItemRequest, path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AF.request("\(Self.apiContentsBase)/\(path)", method: .put, parameters: request, encoder: JSONParameterEncoder.default, headers: headers)
            .responseDecodable(of: PutItemResponse.self, decoder: decoder, completionHandler: makeVoidCompletion(completion))
    }

    func putItem(item: ContentItem, content: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        putItem(request: .init(from: item, content: content), path: item.path, completion: completion)
    }

    // MARK: Delete
    
    func deleteItem(request: DeleteItemRequest, path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AF.request("\(Self.apiContentsBase)/\(path)", method: .delete, parameters: request, encoder: JSONParameterEncoder.default, headers: headers)
            .responseDecodable(of: PutItemResponse.self, decoder: decoder, completionHandler: makeVoidCompletion(completion))
    }
    
    func deleteItem(item: ContentItem, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteItem(request: .init(sha: item.sha), path: item.path, completion: completion)
    }
    
    func deleteItem(message: String, path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        fetchList(path: path) { result in
            switch result {
            case let .success(items):
                if let item = items.first {
                    self.deleteItem(item: item, completion: completion)
                }
                completion(.success(()))
                
            case let .failure(err):
                completion(.failure(err))
            }
        }
        
    }
    
    func deleteDirectory(message: String, path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        fetchList(path: path) { result in
            switch result {
            case let .success(items):
                let group = DispatchGroup()
                
                var error: Error?
                
                for item in items {
                    
                    switch item.type {
                    case .dir:
                        group.enter()
                        self.deleteDirectory(message: message, path: item.path) { _ in group.leave() }
                    
                    case .file:
                        group.enter()
                        self.deleteItem(item: item) { result in
                            if case let .failure(err) = result {
                                error = err
                            }
                            group.leave()
                        }
                        
                    default:
                        break
                    }
                }

                group.notify(queue: .main) {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
                
            case let .failure(err):
                completion(.failure(err))
            }
        }
    }
    
    func deletePage(message: String, page: Page, pagename: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let group = DispatchGroup()
        
        var error: Error?
        
        let completion = { (result: Result<Void, Error>) in
            if case let .failure(err) = result {
                error = err
            }
            group.leave()
        }
        
        if let resourcesPath = page.metadata.resourcesDirectoryPath(pagename: pagename) {
            group.enter()
            deleteDirectory(message: message, path: resourcesPath, completion: completion)
        } else {
            // TODO: replace resourcesDirectoryPath optional to exceptions
        }
        
        if let markdownPath = page.metadata.markdownPath(pagename: pagename) {
            group.enter()
            deleteItem(message: message, path: markdownPath, completion: completion)
        } else {
            // TODO: replace markdownPath optional to exceptions
        }
        
        group.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// MARK: Completion helpers

private extension GithubService {
    func makeCompletion<T>(_ completion: @escaping (Result<T, Error>) -> Void) -> (DataResponse<T, AFError>) -> Void {
        {
            completion($0.result.mapError { $0 as Error })
        }
    }

    func makeVoidCompletion<T>(_ completion: @escaping (Result<Void, Error>) -> Void) -> (DataResponse<T, AFError>) -> Void {
        makeCompletion { completion($0.map { _ in () }) }
    }
}
