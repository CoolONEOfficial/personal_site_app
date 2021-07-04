//
//  MainView.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import SwiftUI
import Parma

struct ListEntry: Identifiable, Hashable, Equatable {
    enum Data: Equatable, Hashable {
        case section(ContentType)
        case item(ContentItem)
    }
    
    let id = UUID()
    let data: Data
    var children: [Self]? = nil
}

struct MainView<Model: MainViewModeling>: View {
    @StateObject var viewModel: Model

    @ViewBuilder
    var entriesSection: some View {
        let data = viewModel.items.enumerated().map(\.element).map { ListEntry(data: .section($0.key), children: $0.value.map { ListEntry(data: .item($0)) }) }
        if let error = viewModel.error {
            ErrorView(error: error)
        } else if !data.isEmpty {
            List(data, children: \.children) { entry in
                switch entry.data {
                case let .section(type):
                    Text(type.name)
                
                case let .item(item):
                    NavigationLink(item.name, destination: PageView(viewModel: PageViewModel(item: item)))
                }
            }
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .navigation){
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
                #endif
            }
        } else {
            ProgressView("Loading...")
        }
    }
    
    #if os(macOS)
    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    #endif

    var body: some View {
        NavigationView {
            entriesSection
                .navigationTitle("Sections")
                .listStyle(SidebarListStyle())
        }.onAppear {
            viewModel.viewAppear()
            #if os(iOS)
            UIScrollView.appearance().keyboardDismissMode = .onDrag
            #endif
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: MainViewModel())
    }
}
