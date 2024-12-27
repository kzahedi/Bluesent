//
//  Settings.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    var body: some View {
        
        TabView {
            ProfileSettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            
            ListOfAccountsView()
                .tabItem {
                    Label("List of Accounts", systemImage: "paintpalette")
                }
            
            CrawlerSettings()
                .tabItem {
                    Label("Crawler Settings", systemImage: "hand.raised")
                }
            
            AnalyticsSettings()
                .tabItem {
                    Label("Analytics Settings", systemImage: "hand.raised")
                }
            
            PrivacySettingsView()
                .tabItem {
                    Label("MongoDB Settings", systemImage: "hand.raised")
                }
        }
        .frame(width: 800, height: 500)
    }
}




struct PrivacySettingsView: View {
    struct Ocean: Identifiable {
        let name: String
        let id = UUID()
    }
    
    private var oceans = [
        Ocean(name: "Pacific"),
        Ocean(name: "Atlantic"),
        Ocean(name: "Indian"),
        Ocean(name: "Southern"),
        Ocean(name: "Arctic")
    ]
    
    
    var body: some View {
        List(oceans) {
            Text($0.name)
        }
    }
}

#Preview {
    SettingsView()
}
