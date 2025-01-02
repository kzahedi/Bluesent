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
                NavigationLink(destination: AccountSettingsNavigation()){
                    Label("Scraping", systemImage: "arrow.2.circlepath")
                }
                .padding()
                NavigationLink(destination:AccountStastNavigation()){
                    Label("Statistics", systemImage: "magnifyingglass")
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
