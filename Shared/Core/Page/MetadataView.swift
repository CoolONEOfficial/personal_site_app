//
//  MetadataView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 05.07.2021.
//

import SwiftUI

extension String {
    var withoutExt: String {
        String(self[startIndex ..< (firstIndex(of: ".") ?? endIndex)])
    }
}

struct MetadataView: View {
    @Binding var metadata: PageMetadata
    var filename: Binding<String>
    @State private var endDate: Bool = false
    @Binding var logo: ImageOrUrl? {
        didSet {
            let newVal = logo != nil ? ".png" : ""
            if metadata.logo != newVal {
                metadata.logo = newVal
            }
        }
    }
    @Binding var singleImage: ImageOrUrl? {
        didSet {
            let newVal = singleImage != nil ? ".png" : ""
            if metadata.singleImage != newVal {
                metadata.singleImage = newVal
            }
        }
    }

    init(metadata: Binding<PageMetadata>, filename: Binding<String>, logo: Binding<ImageOrUrl?>, singleImage: Binding<ImageOrUrl?>) {
        self.filename = filename
        self._metadata = metadata
        self._logo = logo
        self._singleImage = singleImage
        endDate = metadata.endDate.wrappedValue != nil
    }
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                if let filename = filename {
                    TextField("Filename", text: filename)
                }
                VStack {
                    Text("Description")
                    TextEditor(text: $metadata.description)
                }
                
                DatePicker("Start date", selection: $metadata.date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .frame(maxHeight: 400)
                Toggle("End date enabled", isOn: $endDate)
                if endDate {
                    DatePicker("End date", selection: .init(get: { metadata.endDate ?? Date() }, set: { metadata.endDate = $0 }))
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .frame(maxHeight: 400)
                }
                ListText(title: "Tags", text: $metadata.tags)
                ListText(title: "Videos", text: $metadata.videos)
                ImagePickerView(title: "Logo", images: .init(get: { [logo].compactMap { $0 } }, set: { logo = $0.first }), selectionLimit: 1)
                ImagePickerView(title: "Single image", images: .init(get: { [singleImage].compactMap { $0 } }, set: { singleImage = $0.first }), selectionLimit: 1)
            }
            if let project = metadata.project {
                projectSection(project)
            }
            if let career = metadata.career {
                careerSection(career)
            }
            if let book = metadata.book {
                bookSection(book)
            }
        }
    }

    func projectSection(_ project: ProjectMetadata) -> some View {
        Section(header: Text("Project")) {
            EnumPicker(
                title: "Type",
                options: ProjectType.allCases,
                optionToString: \.rawValue,
                stringToOption: { .init(rawValue: $0) },
                selected: .init(
                    get: { project.type },
                    set: { metadata.project?.type = $0 }
                )
            )
            MultiSelector(
                label: Text("Platform"),
                options: ProjectPlatform.allCases,
                optionToString: \.rawValue,
                selected: .init(
                    get: { .init(project.platforms) },
                    set: { metadata.project?.platforms = .init($0) }
                )
            )
            MultiText(
                label: Text("Marketplaces"),
                options: ProjectMarketplace.allCases,
                optionToString: \.rawValue,
                selected: .init(
                    get: { project.marketplacesParsed ?? [:] },
                    set: { metadata.project?.marketplaces = $0.map { "\"\($0.key): \($0.value)\"" } }
                )
            )
        }
    }

    func careerSection(_ career: CareerMetadata) -> some View {
        Section(header: Text("Career")) {
            EnumPicker(
                title: "Type",
                options: JobType.allCases,
                optionToString: \.rawValue,
                stringToOption: { .init(rawValue: $0) },
                selected: .init(
                    get: { career.type },
                    set: { metadata.career?.type = $0 }
                )
            )
            TextField(
                "Position",
                text: .init(
                    get: { career.position },
                    set: { metadata.career?.position = $0 }
                )
            )
        }
    }
    
    func bookSection(_ book: BookMetadata) -> some View {
        Section(header: Text("Book")) {
            TextField(
                "Author",
                text: .init(
                    get: { book.author },
                    set: { metadata.book?.author = $0 }
                )
            )
            TextField(
                "Organisation",
                text: .init(
                    get: { book.organisation },
                    set: { metadata.book?.organisation = $0 }
                )
            )
        }
    }
}

extension ProjectPlatform: Identifiable {
    var id: String { rawValue }
}

extension ProjectType: Identifiable {
    var id: String { rawValue }
}

extension ProjectMarketplace: Identifiable {
    var id: String { rawValue }
}

extension JobType: Identifiable {
    var id: String { rawValue }
}

//
//struct MetadataView_Previews: PreviewProvider {
//    static var previews: some View {
//        MetadataView()
//    }
//}
