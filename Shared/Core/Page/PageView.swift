//
//  RowView.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 04.07.2021.
//

import SwiftUI

struct PageView<Model: PageViewModeling>: View {
    @ObservedObject var viewModel: Model
    @State var finishAlert: Bool = false
    @Binding var isPageActive: Bool
    var needsToRefresh: () -> Void
    
    var body: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading...").onFirstAppear(perform: viewModel.onAppear)
            
        case let .error(error):
            ErrorView(error: error)
            
        case let .page(page):
            #if os(iOS)
                pageView(page)
                .navigationBarOpaque()
                .navigationBarTitleDisplayMode(.inline)
            #else
                pageView(page)
            #endif
        }
    }
    
    func pageView(_ page: Page) -> some View {
        GeometryReader { geo in
            if geo.size.width > 600 {
                NavigationView {
                    editorView(page: page)
                    metadataView(page: page)
                    previewView(page: page)
                }
            } else {
                tabs(page)
                    .toolbar {
                        ToolbarItem(placement: placement) {
                            Picker(
                                selection: $viewModel.tab,
                                label: Text("")) {
                                Text("Edit").tag(Tab.editor)
                                Text("Meta").tag(Tab.metadata)
                                Text("Preview").tag(Tab.preview)
                            }.pickerStyle(SegmentedPickerStyle()).frame(width: 180)
                        }
                        ToolbarItem {
                            Button(action: {
                                finishAlert = true
                            }) {
                                ImageView(systemName: "checkmark").imageScale(.large)
                            }
                            .disabled(!viewModel.applyEnabled)
                        }
                    }
            }
        }
        .alert(isPresented: $finishAlert) {
            Alert(
                title: Text(viewModel.isNewPage
                                ? "Are you sure you want to create page?"
                                : "Are you sure you want to apply changes?"),
                message: Text(""),
                primaryButton: .default(Text("Yes"), action: { viewModel.apply { dismiss(withRefresh: true) } }),
                secondaryButton: .cancel()
            )
        }
    }
    
    func dismiss(withRefresh: Bool) {
        isPageActive = false
        if withRefresh {
            needsToRefresh()
        }
    }

    var placement: ToolbarItemPlacement {
        #if os(macOS)
            return .navigation
        #else
            return .principal
        #endif
    }
    
    @ViewBuilder
    func tabs(_ page: Page) -> some View {
        switch viewModel.tab {
        case .preview:
            previewView(page: page)
            
        case .editor:
            editorView(page: page)
            
        case .metadata:
            metadataView(page: page)
        }
    }

    func editorView(page: Page) -> some View {
        EditorView(text: .init(get: { page.content }, set: { text in
            viewModel.state.updatePage { page in
                page.content = text
            }
            viewModel.updateView()
        }), attachedImages: $viewModel.attachedImages.value)
        
    }

    func metadataView(page: Page) -> some View {
        MetadataView(metadata: .init(get: { page.metadata }, set: { meta in
            page.metadata = meta
            viewModel.updateView()
        }), pagename: $viewModel.pagename, logo: $viewModel.logo.value, singleImage: $viewModel.singleImage.value)
        
    }
    
    func previewView(page: Page) -> some View {
        PreviewView(
            viewModel: PreviewViewModel(
                content: page.content,
                type: page.metadata.type!,
                pagename: viewModel.pagename
            ),
            page: page,
            attachedImages: $viewModel.attachedImages.value
        )
    }
}
