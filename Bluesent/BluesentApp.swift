//
//  BluesentApp.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 23.12.24.
//

import SwiftUI

@main
struct BluesentApp: App {
    private let accountStore = AccountStore.shared
    
    var body: some Scene {
        WindowGroup{
            MainNavigationView()
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
        Settings {
            SettingsView()
        }
    }
}
