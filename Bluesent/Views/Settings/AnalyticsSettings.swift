//
//  AnalysisView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 27.12.24.
//

import Foundation
import SwiftUI

struct AnalyticsSettings: View {
   @State var updateSentiment: Bool = false

    var body: some View {
        Form {
            Section {
                
                HStack {
                    Toggle(isOn: $updateSentiment) {
                        Text("Force update sentiments")
                    }
                    .onChange(of: updateSentiment) {
                        UserDefaults.standard.set(updateSentiment, forKey: labelForceUpdateSentiments)
                    }
                    .onAppear() {
                        updateSentiment = UserDefaults.standard.bool(forKey: labelForceUpdateSentiments)
                    }
                }
            }
        }
        .frame(width: 400)
        .onAppear() {
            initialiseValues()
        }
    }
    
    private func initialiseValues() {
        updateSentiment = UserDefaults.standard.bool(forKey: labelForceUpdateSentiments)
    }
}

#Preview{
    CrawlerSettings()
}
