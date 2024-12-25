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
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
        .frame(width: 450, height: 250)
    }
}
 
struct ProfileSettingsView: View {
    var body: some View {
        Text("Profile Settings")
            .font(.title)
    }
}
 
 
struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance Settings")
            .font(.title)
    }
}
 
 
struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .font(.title)
    }
}
