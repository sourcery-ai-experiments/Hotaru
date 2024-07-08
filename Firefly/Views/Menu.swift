//
//  Menu.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/11/26.
//

import AlertToast
import SwiftUI

struct Menu: View {

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // If you want a blur effect
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)

        // Customize the color to make it more or less translucent
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)

        // Use this appearance for both standard and scrolled content
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    @State private var showToast = false
    @StateObject private var tokenSettingsValue = TokenSettingsViewModel()
    //    @ObservedObject var toastHandler: ToastHandlerModel
    @State private var tokenSheetShown = false
    @State private var hasCheckedToken = false

    var body: some View {
        TabView {
            AboutView()
                .ignoresSafeArea(.all)
                .tabItem { Image(systemName: "house") }
                .tag(1)
            TransactionsView()
                .tabItem { Label("Transactions", systemImage: "list.bullet.circle.fill") }
                .tag(2)
            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "banknote.fill")
                }
            Settings()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }

        }
        .sheet(isPresented: $tokenSheetShown) {
            TokenSettings()
        }
        .task {
            if !hasCheckedToken {
                do {
                    try await checkToken()
                } catch {
                    tokenSheetShown = true
                }
            }
        }.transition(.opacity)
        .ignoresSafeArea(.all)

        .toast(isPresenting: $showToast, tapToDismiss: true) {
            AlertToast(displayMode: .hud, type: .regular, title: "TEST")
        }
    }
    private func checkToken() async throws {
        do {
            try await tokenSettingsValue.testUserAccessInfo()
        } catch CredentialSaveError.accessError {
            tokenSheetShown = true
        }
    }
}

//#Preview {
//    Menu()
//}
