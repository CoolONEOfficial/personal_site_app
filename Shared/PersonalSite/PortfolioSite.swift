//
//  PersonalSite.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 06.08.2021.
//

import Foundation
import Publish
import Ink
import Plot

public struct PortfolioSite: Website {
    public enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case projects
        case books
        case events
        case career
        case achievements
    }

    public struct ItemMetadata: WebsiteItemMetadata {
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

    public var url = URL(string: "https://coolone.ru")!
    public var name = "Сайт Николая Трухина"
    public var description = "Здесь собрана вся информация проектах, мероприятиях, книгах и многое другое"
    public var language: Language { .russian }
    public var imagePath: Path? { "/avatar.jpg" }
    public var favicon: Favicon? { .init(path: "/avatar.jpg", type: "image/jpg") }
}

extension PortfolioSite.ItemMetadata {
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }()
    
    var parsedEndDate: Date? {
        if let endDate = endDate {
            return PortfolioSite.ItemMetadata.dateFormatter.date(from: endDate)
        }
        return nil
    }
}


extension PublishingStep where Site == PortfolioSite {
    static func addDefaultSectionTitles() -> Self {
        .step(named: "Default section titles") { context in
            context.mutateAllSections { section in
                switch section.id {
                case .projects:
                    section.title = "Проекты"
                case .books:
                    section.title = "Книги"
                case .events:
                    section.title = "Мероприятия"
                case .career:
                    section.title = "Карьера"
                case .achievements:
                    section.title = "Достижения"
                }
            }
        }
    }
    
    static func addItemPages() -> Self {
        .step(named: "Add items pages") { context in
            let chunks = context.allItems(
                sortedBy: \.date,
                order: .descending
            ).chunked(into: 10)
            for (index, chunk) in chunks.enumerated() {
                let index = index + 1
                context.addPage(.init(path: "/items/\(index)", content: .init(
                    title: "Все посты",
                    description: "Список всех постов",
                    body: .init(node: .makeItemsPageContent(
                        context: context,
                        items: chunk,
                        pageIndex: index,
                        lastPage: chunks.count == index
                    ))
                )))
            }
        }
    }
}

extension Item {
    var id: String {
        let path = self.path.absoluteString
        return String(path[path.lastIndex(of: "/")!..<path.endIndex])
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Collection where Element: Equatable {
    /// Returns the second index where the specified value appears in the collection.
    func secondIndex(of element: Element) -> Index? {
        guard let index = firstIndex(of: element) else { return nil }
        return self[self.index(after: index)...].firstIndex(of: element)
    }
}

