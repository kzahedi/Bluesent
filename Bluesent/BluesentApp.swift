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
    
    var body: some Scene {
        WindowGroup{
            MainNavigationView()
        }
    }
}







//struct BluesentApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    
//    var body: some Scene {
//        WindowGroup{
//            PostsPerDayView()
//        }
//        .commands{
//            CommandMenu("Run") {
//                Button("Feed Crawler") {
//                    do {
//                        try runFeedCrawler()
//                    } catch {
//                        print(error)
//                    }
//                }
//                .keyboardShortcut("1", modifiers: [.command, .shift, .option])
//                Button("Replies Crawer") {
//                    do {
//                        try runRepliesCrawler()
//                    } catch {
//                        print(error)
//                    }
//                }
//                .keyboardShortcut("2", modifiers: [.command, .shift, .option])
//            }
//            CommandMenu("Analytics") {
//                Button("Sentiment Analysis"){
//                    do {
//                        try runSentimentAnalysis()
//                    } catch {
//                        print(error)
//                    }
//                    
//                }
//                .keyboardShortcut("3", modifiers: [.command, .shift, .option])
//                Button("Posts per Day") {
//                    do {
//                        try Statistics().postsPerDay()
//                        appDelegate.openPostsPerDay()
//                    } catch {
//                        print(error)
//                    }
//                }
//            }
//        }
//
//        Settings{
//            SettingsView()
//        }
//    }
//}




class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindow: NSWindow?
    var postsPerDayWindow: NSWindow?
    
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
    
    func openPostsPerDay() {
        if postsPerDayWindow == nil {
            // Create a new SwiftUI-based window for settings
            let view = PostsPerDayView()
            postsPerDayWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            postsPerDayWindow?.title = "Posts per day"
            postsPerDayWindow?.contentView = NSHostingView(rootView: view)
            postsPerDayWindow?.isReleasedWhenClosed = false
        }
        // Center the window on the screen
        postsPerDayWindow?.center()
        
        // Show the settings window
        postsPerDayWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

