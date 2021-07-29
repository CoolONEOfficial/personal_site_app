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
