//
//  FilePicker.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 16.07.2021.
//

import SwiftUI
import Kingfisher

#if os(iOS)
import UIKit
import Photos
#else
import AppKit
#endif

struct ImagePickerButton<T: View>: View {
    @State private var showImagePicker: Bool = false
    var label: () -> T
    var onImagesPicked: (_ images: [Image]) -> Void
    let selectionLimit: Int
    
    init(label: @escaping () -> T, completion onImagesPicked: @escaping (_ images: [Image]) -> Void, selectionLimit: Int = 1) {
        self.label = label
        self.onImagesPicked = onImagesPicked
        self.selectionLimit = selectionLimit
    }
    
    var body: some View {
        Button(action: {
            #if os(iOS)
            showImagePicker = true
            #else
            NSImagePicker(
                selectionLimit: pickerLimit,
                onImagesPicked
            ).pick()
            #endif
        }, label: label)
        .sheet(isPresented: $showImagePicker) {
            #if os(iOS)
            UIImagePicker(selectionLimit: selectionLimit, onImagesPicked)
            #endif
        }
    }
}

enum ImageOrUrl: Equatable {
    case remote(_ path: String, _ url: URL)
    case image(Image)

    var isLocal: Bool {
        if case .image = self {
            return true
        }
        return false
    }
}

extension ImageOrUrl {
    static func remote(_ path: String) -> Self? {
        guard let url = GithubService.rawUrl(path) else { return nil }
        return .remote(path, url)
    }
}

struct Snapshot<T> {
    let original: T
    var value: T
    
    func map<T2>(_ map: (T) -> T2) -> Snapshot<T2> {
        .init(original: map(original), value: map(value))
    }
}

extension Snapshot {
    init(_ val: T) {
        original = val
        value = val
    }
}

struct ImagePickerView: View {
    let title: String
    @Binding var images: [ImageOrUrl]
    let selectionLimit: Int
    
    var pickerLimit: Int { selectionLimit - images.count }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(images.indices, id: \.self) { index in
                        let entry = images[index]
                        imageEntry(entry, index)
                    }
                    
                    if pickerLimit > 1 || pickerLimit > 0 {
                        ImagePickerButton(label: { Text("Add") }, completion: onImagesPicked, selectionLimit: pickerLimit)
                            .disabled(pickerLimit == 0)
                            .frame(width: 100, height: 100)
                    }
                }
            }
        }.padding(.vertical, 8)
    }

    private func imageEntry(_ entry: ImageOrUrl, _ index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            
            switch entry {
            case let .remote(_, url):
                KFImage(url).resizable().scaledToFit().frame(height: 100)

            case let .image(imageVal):
                ImageView(image: imageVal).resizable().scaledToFit().frame(height: 100)
            }

            Button(action: {
                images.remove(at: index)
            }) {
                ImageView(systemName: "xmark").padding(8)
            }
        }
    }
    
    private func onImagesPicked(_ images: [Image]) {
        self.images.append(contentsOf: images.map { .image($0) })
    }
}

#if os(iOS)

import PhotosUI

// https://github.com/ralfebert/ImagePickerView

public struct UIImagePicker: UIViewControllerRepresentable {
    private let onImagesPicked: ([Image]) -> Void
    private let selectionLimit: Int
    @Environment(\.presentationMode) private var presentationMode

    public init(selectionLimit: Int, _ onImagesPicked: @escaping ([UIImage]) -> Void) {
        self.selectionLimit = selectionLimit
        self.onImagesPicked = onImagesPicked
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        let vc = PHPickerViewController(configuration: configuration)
        vc.delegate = context.coordinator
        return vc
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onDismiss: { self.presentationMode.wrappedValue.dismiss() },
            onImagesPicked: self.onImagesPicked
        )
    }

    final public class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        private let onDismiss: () -> Void
        private let onImagesPicked: ([UIImage]) -> Void

        init(onDismiss: @escaping () -> Void, onImagesPicked: @escaping ([UIImage]) -> Void) {
            self.onDismiss = onDismiss
            self.onImagesPicked = onImagesPicked
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var images = [UIImage]()
            let group = DispatchGroup()

            for result in results {
                let itemProvider = result.itemProvider
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        defer { group.leave() }
                        if let image = image as? UIImage {
                            images.append(image)
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.onImagesPicked(images)
                self.onDismiss()
            }
        }

    }

}

#else

public class NSImagePicker: NSObject, NSOpenSavePanelDelegate {
    internal init(selectionLimit: Int, _ onImagesPicked: @escaping ([Image]) -> Void) {
        self.onImagesPicked = onImagesPicked
        self.selectionLimit = selectionLimit
    }
    
    private let selectionLimit: Int
    private let onImagesPicked: ([Image]) -> Void
    
    func pick() {
        let dialog = NSOpenPanel();
        dialog.title = "Choose multiple pictures";
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = false;
        dialog.canChooseDirectories = false;
        dialog.allowsMultipleSelection = true;
        dialog.delegate = self

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let paths = dialog.urls
            let images = paths.compactMap { Image(contentsOf: $0) }
            onImagesPicked(images)
        } else {
            return
        }
    }
}

#endif
