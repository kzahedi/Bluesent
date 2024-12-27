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
    @State var currentNumber: String = "1"
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsView()
        }
//        MenuBarExtra(currentNumber, systemImage: "\(currentNumber).circle") {
//            Button("One") {
//                currentNumber = "1"
//            }
//            .keyboardShortcut("1")
//            Button("Two") {
//                currentNumber = "2"
//            }
//            .keyboardShortcut("2")
//            Button("Three") {
//                currentNumber = "3"
//            }
//            .keyboardShortcut("3")
//            Divider()
//            Button("Settings") {
//                SettingsView().window
//            }
//            .keyboardShortcut(",")
//            Divider()
//            Button("Quit") {
//                NSApplication.shared.terminate(nil)
//            }.keyboardShortcut("q")
//        }
    }
}
