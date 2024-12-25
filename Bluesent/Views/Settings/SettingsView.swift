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
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
        .frame(width: 800, height: 500)
    }
}
 
 

 
struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .font(.title)
    }
}

#Preview {
    SettingsView()
}
