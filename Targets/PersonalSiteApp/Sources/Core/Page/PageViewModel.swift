//
//  PageViewModel.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//
//

import SwiftUI
import PortfolioSite

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
    var pagename: String { get set }
    var isNewPage: Bool { get }
    var attachedImages: Snapshot<[String: LocalRemoteImage]> { get set }
    var logo: Snapshot<LocalRemoteImage?> { get set }
    var singleImage: Snapshot<LocalRemoteImage?> { get set }
    var applyEnabled: Bool { get }
    func apply(dismissCompletion: @escaping () -> Void)
    func onAppear()
    func updateView()
}

class PageViewModel: PageViewModeling {
    private let githubService: GithubServicing = GithubService()

    @Published var state: PageViewState = .loading
    @Published var tab: Tab = .editor
    @Published var attachedImages = Snapshot([String: LocalRemoteImage]())
    @Published var logo: Snapshot<LocalRemoteImage?> = .init(nil)
    @Published var singleImage: Snapshot<LocalRemoteImage?> = .init(nil)
    @Published var pagename: String
    
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
    
    init(item: ContentItem, pagename: String) {
        self.itemOrType = .item(item)
        self.pagename = pagename
    }

    func onAppear() {
        guard case let .item(item) = itemOrType else { return }
        githubService.fetchPage(item: item) { [self] result in
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
        pagename = ""
    }
    
    func updateView() {
        self.objectWillChange.send()
    }
    
    var applyEnabled: Bool {
        !pagename.isEmpty
    }

    func apply(dismissCompletion: @escaping () -> Void) {
        guard let page = state.page,
              let content = page.string()?.data(using: .utf8) else { return }

        defer { state = .loading }
        
        let group = DispatchGroup()
        
        group.enter()
        switch itemOrType {
        case let .item(item):
            githubService.overwriteItem(item: item, content: content) { _ in group.leave() }
        case let .type(type):
            githubService.putItem(path: type.markdownPath(pagename: pagename), content: content) { _ in group.leave() }
        }

        putImage(page: page, image: singleImage, filename: "singleImage", ext: page.metadata.singleImage, group: group)
        putImage(page: page, image: logo, filename: "logo", ext: page.metadata.logo, group: group)
        
        for (path, newImage) in attachedImages.value.minus(dict: attachedImages.original) {
            let oldImage = attachedImages.original[path]
            
            let imageName = path.filename.withoutExt
            putImage(page: page, image: .init(original: oldImage, value: newImage), filename: imageName, ext: ".png", group: group)
        }
        
        group.notify(queue: .main, execute: dismissCompletion)
    }

    func putImage(page: Page, image: Snapshot<LocalRemoteImage?>, filename: String, ext: String?, group: DispatchGroup, withMiniature: Bool = false) {
        if withMiniature, let imageValue = image.value?.image {
            var image = image

            let imageValueResized = imageValue.scalePreservingAspectRatio(to: .init(width: 400, height: 400))
            image.value?.image = imageValueResized

            putImage(page: page, image: image, filename: filename + "_400x400", ext: ext, group: group)
        }
        guard let path = page.metadata.type?.path(pagename, filename, ext) else { return }
        
        group.enter()
        
        githubService.fetchItem(path: path) { [self] result in
            defer { group.leave() }
            guard let item = try? result.get() else { return }

            switch (image.original, image.value) {
            case let (.none, .local(image)), let (.remote, .local(image)):
                guard let imageData = image.pngData() else { return }

                group.enter()
                githubService.overwriteItem(item: item, content: imageData) { _ in group.leave() }

            case (.remote, .none):
                group.enter()
                githubService.deleteItem(item: item) { _ in group.leave() }
                
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

extension Dictionary where Key: Comparable, Value: Equatable {
    func minus(dict: [Key:Value]) -> [Key:Value] {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce([Key:Value]()) { (res, entry) -> [Key:Value] in
            var res = res
            res[entry.0] = entry.1
            return res
        }
    }
}

extension Image {
    #if os(iOS)
    func scalePreservingAspectRatio(to newSize: CGSize) -> Image {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = newSize.width / size.width
        let heightRatio = newSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
    #else
    func scalePreservingAspectRatio(to newSize: CGSize) -> Image? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }

        return nil
    }
    #endif
}
