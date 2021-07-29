//
//  PreviewView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 05.07.2021.
//

import SwiftUI
import Parma
import Kingfisher

struct PreviewView: View {
    let page: Page
    @Binding var attachedImages: [String: Image]
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                Parma(page.content, alignment: .leading, render: self).padding(8)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

//struct PreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewView()
//    }
//}

extension PreviewView: ParmaRenderable {
    func imageView(with urlString: String, altTextView: AnyView?) -> AnyView {
        .init(image(urlString).frame(maxWidth: 300, maxHeight: 300))
    }
    
    private func image(_ path: String) -> AnyView {
        if let image = attachedImages[path] {
            return .init(ImageView(image: image).resizable().scaledToFit())
        } else {
            return .init(KFImage(URL(string: GithubService.repoUrl + "/raw/master/Resources" + path)!).resizable().scaledToFit())
        }
    }
}
