//
//  BluesentApp.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 23.12.24.
//

import SwiftUI
import Security

@main
struct BluesentApp: App {
    var body: some Scene {
        let _ = KeychainHelper.shared.getPassword()
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsView()
        }
    }
}
