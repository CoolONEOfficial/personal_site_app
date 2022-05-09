//
//  EditorView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 05.07.2021.
//

import SwiftUI
import Ink
import Kingfisher
import Introspect
import HighlightedTextEditor

struct EditorView: View {
    @Binding var text: String
    @Binding var attachedImages: [String: LocalRemoteImage]
    @Binding var metadata: PageMetadata
    @Binding var pagename: String
    @State private var selection: NSRange = .init()

    private var images: [String: LocalRemoteImage] {
        var images = [String: LocalRemoteImage]()
        let _ = Ink.MarkdownParser(modifiers: [Ink.Modifier(target: .images) { html, markdown in
            let str = String(markdown[markdown.firstIndex(of: "(")! ... markdown.lastIndex(of: ")")!].dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !str.isEmpty, let image = LocalRemoteImage.remote("Resources/\(metadata.type?.rawValue ?? "")/\(pagename)/" + str) else { return html }
            images[str] = image
            return html
        }]).html(from: text)
        return images
    }
    
    var body: some View {
        VStack {
            imagesStack.frame(height: 100)
            HighlightedTextEditor(text: $text, highlightRules: [])
                .onSelectionChange { range in
                    selection = range
                }
                .onTextChange { _ in
                    attachedImages = attachedImages
                        .filter { $0.value.isLocal }
                        .merging(images) { $1 }
                        .filter { text.contains("(\($0.key))") }
                }
            ScrollView(.horizontal) {
                HStack {
                    sliderButton.padding()
                    photoButton.padding()
                }
            }
        }.onAppear {
            guard attachedImages.isEmpty, !text.isEmpty else { return }
            self.attachedImages = images
        }
    }
    
    private var imagesStack: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(attachedImages.sorted { $0.key < $1.key }, id: \.key) { (path, image) in
                    ZStack(alignment: .topTrailing) {
                        switch image {
                        case let .remote(_, url):
                            KFImage(url).placeholder {
                                ImagePickerButton(label: { ImageView(systemName: "plus") }) { images in
                                    guard let image = images.first else { return }
                                    attachedImages[path] = .local(image)
                                }.frame(width: 100, height: 100)
                            }.resizable().scaledToFit()

                        case let .local(image):
                            ImageView(image: image).resizable().scaledToFit()
                        }

                        Button(action: {
                            text = text.replacingOccurrences(of: path, with: "")
                        }) {
                            ImageView(systemName: "xmark").padding(8)
                        }
                    }
                }
            }
        }
    }
    
    private var sliderButton: some View {
        ImagePickerButton(
            label: { ImageView(systemName: "photo.on.rectangle") },
            selectionLimit: 16
        ) { images in
            var pickerText = ["{ }"]

            for image in images {
                pickerText.append(appendImage(image))
            }

            text.insert(
                contentsOf: pickerText.enumerated()
                    .map { (index, text) in "\(index + 1). \(text)" }
                    .joined(separator: "\n"),
                at: text.index(text.startIndex, offsetBy: selection.lowerBound)
            )
        }
    }

    private var photoButton: some View {
        ImagePickerButton(
            label: { ImageView(systemName: "photo") }
        ) { images in
            guard let image = images.first else { return }

            text.insert(
                contentsOf: appendImage(image),
                at: text.index(text.startIndex, offsetBy: selection.lowerBound)
            )
        }
    }

    private func appendImage(_ image: Image) -> String {
        let keyName = nextKey
        attachedImages[keyName] = .local(image)
        return "![ ](\(keyName))"
    }

    private var nextKey: String {
        var index = 1
        while attachedImages.keys.contains(Self.keyName(index)) {
            index += 1
        }
        return Self.keyName(index)
    }

    static private func keyName(_ index: Int) -> String {
        "\(index)_400x400.jpg"
    }
}

extension String {
    func matches(_ text: String!) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: self, options: [])
            let nsString = text as NSString

            let results = regex.matches(in: text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}

        } catch let error as NSError {

            print("invalid regex: \(error.localizedDescription)")

            return []
        }
            
    }
}

//struct EditorView_Previews: PreviewProvider {
//    static var previews: some View {
//        EditorView()
//    }
//}
