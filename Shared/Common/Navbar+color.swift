//
//  Navbar+color.swift
//  personal_site_app
//
//  Created by Nickolay Truhin on 05.07.2021.
//

import SwiftUI

#if os(iOS)
extension View {
    func navigationBarColor(_ backgroundColor: UIColor, textColor: UIColor?) -> some View {
        self.modifier(NavigationBarModifier(backgroundColor: backgroundColor, textColor: textColor))
    }

    func navigationBarOpaque() -> some View {
        self.navigationBarColor(.systemBackground, textColor: nil)
    }
}

struct NavigationBarModifier: ViewModifier {
    var backgroundColor: UIColor
    var textColor: UIColor?

    init(backgroundColor: UIColor, textColor: UIColor?) {
        self.backgroundColor = backgroundColor
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = .clear
        if let textColor = textColor ?? self.textColor {
            self.textColor = textColor
            coloredAppearance.titleTextAttributes = [.foregroundColor: textColor]
            coloredAppearance.largeTitleTextAttributes = [.foregroundColor: textColor]
        }

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = textColor
    }

    func body(content: Content) -> some View {
        ZStack{
            content
            VStack {
                GeometryReader { geometry in
                    Color(self.backgroundColor)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
    }
}

#endif

#if os(iOS)
struct WillDisappearHandler: UIViewControllerRepresentable {
    func makeCoordinator() -> WillDisappearHandler.Coordinator {
        Coordinator(onWillDisappear: onWillDisappear)
    }

    let onWillDisappear: () -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<WillDisappearHandler>) -> UIViewController {
        context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<WillDisappearHandler>) {
    }

    typealias UIViewControllerType = UIViewController

    class Coordinator: UIViewController {
        let onWillDisappear: () -> Void

        init(onWillDisappear: @escaping () -> Void) {
            self.onWillDisappear = onWillDisappear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            onWillDisappear()
        }
    }
}
#else
struct WillDisappearHandler: NSViewControllerRepresentable {
    func makeCoordinator() -> WillDisappearHandler.Coordinator {
        Coordinator(onWillDisappear: onWillDisappear)
    }

    let onWillDisappear: () -> Void

    func makeNSViewController(context: NSViewControllerRepresentableContext<WillDisappearHandler>) -> NSViewController {
        context.coordinator
    }

    func updateNSViewController(_ uiViewController: NSViewController, context: NSViewControllerRepresentableContext<WillDisappearHandler>) {
    }

    typealias NSViewControllerType = NSViewController

    class Coordinator: NSViewController {
        let onWillDisappear: () -> Void

        init(onWillDisappear: @escaping () -> Void) {
            self.onWillDisappear = onWillDisappear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillDisappear() {
            super.viewWillDisappear()
            onWillDisappear()
        }
    }
}
#endif

struct WillDisappearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(WillDisappearHandler(onWillDisappear: callback))
    }
}

extension View {
    func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
        self.modifier(WillDisappearModifier(callback: perform))
    }
}
