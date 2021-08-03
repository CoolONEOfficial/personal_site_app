//
//  MainView.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import SwiftUI
import Parma

struct MainView<Model: MainViewModeling>: View {
    @ObservedObject var viewModel: Model
    @State var isPageActive = [ContentType: [String: Bool]]()
    
    @State private var isGroupOpened: ContentType?
    
    func isActive(_ k1: ContentType, _ k2: String) -> Binding<Bool> {
        Binding(get: { isPageActive[k1, default: [:]][k2, default: false] }, set: { isPageActive[k1, default: [:]][k2] = $0 })
    }
    
    func delete(type: ContentType, at offsets: IndexSet) {
        viewModel.state.updateItems { items in
            items[type]?.remove(atOffsets: offsets)
        }
        viewModel.onDelete(type: type, at: offsets)
    }
    
    func list(_ items: [ContentType: [ContentItem]]) -> some View {
        List {
            ForEach(items.sorted { $0.key.rawValue < $1.key.rawValue }, id: \.key.rawValue) { (type, items) in
                DisclosureGroup(
                    isExpanded: .init(
                        get: { type == isGroupOpened },
                        set: { isGroupOpened = $0 ? type : nil }
                    )
                ) {
                    ForEach(items) { item in
                        let isActive = self.isActive(type, item.name)
                        NavigationLink(item.name, destination: PageView(viewModel: PageViewModel(item: item, pagename: item.name.withoutExt), isPageActive: isActive), isActive: isActive)
                    }
                    .onDelete { delete(type: type, at: $0) }

                    let isActive = isActive(type, "new")
                    NavigationLink("Create new", destination: PageView(viewModel: PageViewModel(type: type), isPageActive: isActive), isActive: isActive)
                } label: {
                    Text(type.name)
                }
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
        ZStack {
            switch viewModel.state {
            case let .error(error):
                ErrorView(error: error)

            case let .items(items):
                list(items)
            }

            if viewModel.isLoading {
                ZStack(alignment: .center) {
                    Rectangle().fill(Color.gray.opacity(0.3))
                    ProgressView("Loading...")
                }.ignoresSafeArea(.all, edges: .all)
            }
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
                .navigationBarHidden(viewModel.isLoading)
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
