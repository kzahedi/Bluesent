//
//  BluesentApp.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 23.12.24.
//

import SwiftUI

@main
struct BluesentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var showSettings : Bool = false
    
    var body: some Scene {
        MenuBarExtra("",systemImage: "message.badge.waveform.fill") {
            Menu("Run") {
                Button("Feed Crawler") {
                    do {
                        try runFeedCrawler()
                    } catch {
                        print(error)
                    }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift, .option])
                Button("Replies Crawer") {
                    do {
                        try runRepliesCrawler()
                    } catch {
                        print(error)
                    }
                }
                .keyboardShortcut("2", modifiers: [.command, .shift, .option])
                Button("Sentiment Analysis"){
                    do {
                        try runSentimentAnalysis()
                    } catch {
                        print(error)
                    }
                    
                }
                .keyboardShortcut("3", modifiers: [.command, .shift, .option])
                
            }
            Menu("Analytics") {
                Button("Posts per Day") {
                    do {
                        try Statistics().postsPerDay()
                    } catch {
                        print(error)
                    }
                }
            }
            Divider()
            Button("Setting") {
                appDelegate.openSettingsWindow()
            }.keyboardShortcut(",")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
        
    }
    
    func runFeedCrawler() throws {
        Task {
            let blueskyCrawler = BlueskyCrawler()
            try await blueskyCrawler.runFeedsScraper()
        }
    }
    
    func runRepliesCrawler() throws {
        Task {
            let blueskyCrawler = BlueskyCrawler()
            try await blueskyCrawler.runRepliesCrawler()
        }
    }
    
    func runSentimentAnalysis() throws {
        Task {
            try await SentimentAnalysis().runSentimentAnalysis()
        }
    }
    
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindow: NSWindow?

    func openSettingsWindow() {
        if settingsWindow == nil {
            // Create a new SwiftUI-based window for settings
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "Settings"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.isReleasedWhenClosed = false
        }
        // Center the window on the screen
        settingsWindow?.center()
         
        // Show the settings window
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    
}
