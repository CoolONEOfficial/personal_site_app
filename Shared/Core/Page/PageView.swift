//
//  RowView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//

import SwiftUI
import Parma

struct PageView<Model: PageViewModeling>: View {
    @StateObject var viewModel: Model
    
    var body: some View {
        if let error = viewModel.error {
            ErrorView(error: error)
        } else if let page = viewModel.page {
            GeometryReader { geo in
                if geo.size.width > 600 {
                    HStack(spacing: 32) {
                        textEditor(page)
                        parma(page)
                    }//.padding(geo.safeAreaInsets).edgesIgnoringSafeArea(.vertical)
                } else {
                    editorOrPreview(page)
                    //.padding(geo.safeAreaInsets).edgesIgnoringSafeArea(.vertical)
                        .toolbar {
                            ToolbarItem(placement: placement) {
                                Picker(
                                    selection: $viewModel.editor,
                                    label: Text("")) {
                                    Text("Edit").tag(true)
                                    Text("Preview").tag(false)
                                }.pickerStyle(SegmentedPickerStyle()).frame(width: 160)
                            }
                        }
                }
            }
        } else {
            ProgressView("Loading...")
        }
    }
    var placement: ToolbarItemPlacement {
        #if os(macOS)
            return .navigation
        #else
            return .automatic
        #endif
    }
    
    @ViewBuilder
    func editorOrPreview(_ page: Page) -> some View {
        ZStack {
            textEditor(page)
                .opacity(viewModel.editor ? 1 : 0)
            if !viewModel.editor {
                parma(page)
            }
        }
    }
    
    func textEditor(_ page: Page) -> some View {
        TextEditor(text: .init(get: { page.content }, set: {
            viewModel.page?.content = $0
            viewModel.updateView()
        }))
    }

    func parma(_ page: Page) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                Parma(page.content, alignment: .leading).padding(8)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        
    }
}


