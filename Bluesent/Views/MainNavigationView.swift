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
                .padding(.bottom)
                NavigationLink(destination:Text("Analysis")){
                    Label("Analysis", systemImage: "magnifyingglass")
                }
                .padding(.bottom)
                NavigationLink(destination:AccountSettingsNavigation()){
                    Label("Accounts", systemImage: "gearshape")
                }
            }
        }
        .frame(minWidth:200)
    }
}


#Preview {
    MainNavigationView()
}
