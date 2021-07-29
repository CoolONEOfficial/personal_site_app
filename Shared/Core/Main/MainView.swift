//
//  MainView.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import SwiftUI
import Parma

enum ListEntry: Equatable, Hashable, Identifiable {
    case section(ContentType, [Self])
    case item(ContentItem, ContentType)
    case new(ContentType)

    var id: String {
        switch self {
        case let .item(item, _):
            return item.id
        
        case let .section(type, _):
            return type.id

        case let .new(type):
            return type.id
        }
    }
    
    var children: [Self]? {
        guard case let .section(type, children) = self else { return nil }
        return children + [ .new(type) ]
    }
}

struct MainView<Model: MainViewModeling>: View {
    @ObservedObject var viewModel: Model
    @State var isPageActive = [String: [String: Bool]]()

    func data(_ items: [ContentType: [ContentItem]]) -> [ListEntry] {
        items.enumerated().map(\.element).sorted { $0.key.rawValue < $1.key.rawValue }.map { entry in .section(entry.key, entry.value.map { .item($0, entry.key) }) }
    }
    
    func isActive(_ k1: String, _ k2: String) -> Binding<Bool> {
        Binding(get: { isPageActive[k1, default: [:]][k2, default: false] }, set: { isPageActive[k1, default: [:]][k2] = $0 })
    }
    
    func list(_ items: [ContentType: [ContentItem]]) -> some View {
        let data = data(items)
        return List(data, id: \.self, children: \.children) { entry in
            switch entry {
            case let .section(type, _):
                Text(type.name)
            case let .item(item, type):
                let isActive = isActive(type.rawValue, item.name)
                NavigationLink(item.name, destination: PageView(viewModel: PageViewModel(item: item), filename: item.name, isPageActive: isActive), isActive: isActive)
            case let .new(type):
                let isActive = isActive(type.rawValue, "new")
                NavigationLink("Create new", destination: PageView(viewModel: PageViewModel(type: type), filename: "", isPageActive: isActive), isActive: isActive)
            }
        }
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .navigation) {
                
                Button(action: toggleSidebar) {
                    ImageView(systemName: "sidebar.left")
                }
            }
            #endif
        }
    }

    @ViewBuilder
    var entriesSection: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading...")

        case let .error(error):
            ErrorView(error: error)

        case let .items(items):
            list(items)
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
        }.onFirstAppear {
            viewModel.onAppear()
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
