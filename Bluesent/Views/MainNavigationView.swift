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
            List {
                NavigationLink(destination: ScrapingView()){
                    Label("Scraping", systemImage: "arrow.2.circlepath")
                }
                .padding()
                NavigationLink(destination:Text("Analysis")){
                    Label("Analysis", systemImage: "magnifyingglass")
                }
                .padding()
                NavigationLink(destination:AccountSettingsNavigation()){
                    Label("Settings", systemImage: "gearshape")
                }
                .padding()
            }
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity)
    }
}


#Preview {
    MainNavigationView()
}
