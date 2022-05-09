//
//  MainView.swift
//  personal_site_app (iOS)
//
//  Created by Nickolay Truhin on 03.07.2021.
//

import SwiftUI
//import Publish
//import Files
//import Zip
//import GCDWebServers

struct MainView<Model: MainViewModeling>: View {
    @StateObject var viewModel: Model
    @State var isPageActive = [ContentType: [String: Bool]]()
    
    @State private var isGroupOpened: ContentType?
    @State private var deleteCompletion: ((Bool) -> Void)?
    
    private func isActive(_ k1: ContentType, _ k2: String) -> Binding<Bool> {
        Binding(
            get: {
                isPageActive[k1, default: [:]][k2, default: false]
            },
            set: {
                isPageActive[k1, default: [:]][k2] = $0
                if !$0 {
                    onPop()
                }
            }
        )
    }
    
    func onPop() {
        viewModel.refreshContent()
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
                        NavigationLink(
                            item.name,
                            destination: NavigationLazyView(
                                PageView(
                                    viewModel: PageViewModel(item: item, pagename: item.name.withoutExt),
                                    isPageActive: isActive, needsToRefresh: viewModel.refreshContent
                                )
                            ),
                            isActive: isActive
                        )
                    }
                    .onDelete { offsets in
                        let oldItems = viewModel.state.items
                        var deletedItems = [ContentItem]()
                        viewModel.state.updateItems { items in
                            for offset in offsets {
                                if let item = items[type]?.remove(at: offset) {
                                    deletedItems.append(item)
                                }
                            }
                        }
                        deleteCompletion = {
                            viewModel.deleteCompletion(confirm: $0, deletedItems: deletedItems, oldItems: oldItems)
                        }
                    }

                    let isActive = isActive(type, "new")
                    NavigationLink(
                        "Create new",
                        destination: NavigationLazyView(
                            PageView(
                                viewModel: PageViewModel(type: type),
                                isPageActive: isActive, needsToRefresh: viewModel.refreshContent
                            )
                        ),
                        isActive: isActive
                    )
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
        .alert(isPresented: .init(get: { deleteCompletion != nil }, set: { _ in })) {
            Alert(
                title: Text("Are you sure you want to delete page?"),
                message: Text(""),
                primaryButton: .default(Text("Yes"), action: { deleteCompletion?(true) }),
                secondaryButton: .cancel {
                    withAnimation {
                        deleteCompletion?(false)
                        deleteCompletion = nil
                    }
                }
            )
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
                    if viewModel.state.items?.isEmpty == false {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
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
            #if os(iOS)
                .navigationBarHidden(viewModel.isLoading && (viewModel.state.items?.isEmpty ?? true))
            #endif
                .navigationTitle("Sections")
                .listStyle(SidebarListStyle())
        }.onFirstAppear {
            viewModel.refreshContent()
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
