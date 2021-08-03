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
    @State private var selection: NSRange = .init()
    
    init(text: Binding<String>, attachedImages: Binding<[String: LocalRemoteImage]>) {
        self._text = text
        self._attachedImages = attachedImages
    }
    
    private var images: [String: LocalRemoteImage] {
        var images = [String: LocalRemoteImage]()
        let _ = Ink.MarkdownParser(modifiers: [Ink.Modifier(target: .images) { html, markdown in
            let str = String(markdown[markdown.firstIndex(of: "(")! ... markdown.lastIndex(of: ")")!].dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !str.isEmpty, let image = LocalRemoteImage.remote("Resources/" + str) else { return html }
            images[str] = image
            return html
        }]).html(from: text)
        return images
    }

    fileprivate func imagesStack() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(attachedImages.sorted { $0.key < $1.key }, id: \.key) { (path, image) in
                    ZStack(alignment: .topTrailing) {
                        switch image {
                        case let .remote(_, url):
                            KFImage(url).placeholder {
                                ImagePickerButton(label: { Text("Add") }) { images in
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
    
    var body: some View {
        VStack {
            imagesStack().frame(height: 100)
            HighlightedTextEditor(text: $text, highlightRules: [])
                .onSelectionChange { range in
                    selection = range
                }
                .onTextChange { _ in
                    attachedImages = attachedImages.filter { $0.value.isLocal }.merging(images) { $1 }.filter { text.contains("(\($0.key))") }
                }
        }.onAppear {
            guard attachedImages.isEmpty, !text.isEmpty else { return }
            self.attachedImages = images
        }
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
