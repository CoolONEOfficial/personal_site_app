//
//  ViewRepresentable.swift
//  PersonalSiteApp
//
//  Created by Nickolay Truhin on 09.05.2022.
//  Copyright © 2022 coolone.ru. All rights reserved.
//

import Foundation
import SwiftUI

#if os(iOS)
typealias BaseViewRepresentable = UIViewRepresentable
#else
typealias BaseViewRepresentable = NSViewRepresentable
#endif

protocol ViewRepresentable: BaseViewRepresentable {
    #if os(iOS)
    associatedtype ViewType: UIView
    typealias UIViewType = ViewType
    #else
    associatedtype ViewType: NSView
    typealias NSViewType = ViewType
    #endif
    
    func makeView(context: Context) -> ViewType
    func updateView(_ view: ViewType, context: Context)
}

#if os(iOS)

extension ViewRepresentable {
    func makeUIView(context: Context) -> ViewType {
        makeView(context: context)
    }
    
    func updateUIView(_ uiView: ViewType, context: Self.Context) {
        updateView(uiView, context: context)
    }
}

#else

extension ViewRepresentable {
    func makeNSView(context: Context) -> ViewType {
        makeView(context: context)
    }
    
    func updateNSView(_ nsView: ViewType, context: Self.Context) {
        updateView(nsView, context: context)
    }
}

#endif
