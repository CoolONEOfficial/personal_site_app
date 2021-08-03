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
    @Binding var attachedImages: [String: LocalRemoteImage]
    
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
        
        switch attachedImages[path] {
        case let .remote(_, url):
            return .init(KFImage(url).resizable().scaledToFit())
            
            
        case let .local(image):
            return .init(ImageView(image: image).resizable().scaledToFit())
            
        default:
            return .init(Text("Wrong url??"))
        }
    }
}
