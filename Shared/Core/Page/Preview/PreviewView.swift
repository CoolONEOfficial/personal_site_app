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
import UIKit
import Kingfisher
import Publish
import Files

struct PreviewView<Model: PreviewViewModeling>: View {
    @ObservedObject var viewModel: Model
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
            WebView(url: url).ignoresSafeArea().onDisappear(perform: viewModel.onDisappear)
        }
    }
    
    var body: some View {
        content
    }
}

struct WebView: UIViewRepresentable {
    
    var url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        
        webView.scrollView.isScrollEnabled = true
        return webView
    
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let urlValue = url  {
            let request = URLRequest(url: urlValue, cachePolicy: .reloadIgnoringCacheData)
            webView.load(request)
        }
    }
}


