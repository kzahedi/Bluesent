//
//  NavigationView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 29.12.24.
//

import Foundation
import SwiftUI


struct MainNavigationView: View {
    var body: some View {
        NavigationView {
            List{
                NavigationLink("Scraping"){
                    ScrapingView()
                }
                NavigationLink("Analysis"){
                    Text("Analysis")
                }
                NavigationLink("Config"){
                    SettingsView()
                        .padding()
                }
            }
        }
        .frame(minWidth:200)
    }
}


#Preview {
    MainNavigationView()
}
