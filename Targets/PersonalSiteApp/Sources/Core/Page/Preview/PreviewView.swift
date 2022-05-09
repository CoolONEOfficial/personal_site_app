//
//  PreviewView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 05.07.2021.
//

import Foundation
import SwiftUI
import Combine
import WebKit

struct PreviewView<Model: PreviewViewModeling>: View {
    @StateObject var viewModel: Model
    let page: Page
    @Binding var attachedImages: [String: LocalRemoteImage]
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case let .loading(type, progress):
            ProgressView("\(type.name)... \(progress)").onFirstAppear(perform: viewModel.onAppear)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onAppear(perform: viewModel.onAppear)

        case let .error(error):
            ErrorView(error: error)
            
        case let .url(url):
            ZStack(alignment: .topTrailing) {
                WebView(url: url).ignoresSafeArea().onDisappear(perform: viewModel.onDisappear)
                Button(action: {
                    viewModel.reloadRepo()
                }, label: {
                    ImageView(systemName: "repeat")
                        .padding()
                    #if os(iOS)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemBackground)))
                    #endif
                }).padding()
            }
            
        }
    }
    
    var body: some View {
        content
    }
}

struct WebView: ViewRepresentable {
    typealias ViewType = WKWebView
    
    var url: URL?
    
    func makeView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        
        #if os(iOS)
        webView.scrollView.isScrollEnabled = true
        #endif
        return webView
    
    }
    
    func updateView(_ webView: WKWebView, context: Context) {
        if let urlValue = url  {
            let request = URLRequest(url: urlValue, cachePolicy: .reloadIgnoringCacheData)
            webView.load(request)
        }
    }
}
