//
//  ControlPanel.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import SwiftUI

struct ControlPanel: View {
    @State private var showingAlert = false
    
    @State private var limit: String = ""
    @State private var targetAccountHandle: String = ""
    @State private var appPassword: String = ""
    @State private var sourceAccount: String = ""
    @State private var iLimit: Int = 0
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                Text("Account")
                Spacer(minLength: 47)
                TextField("Bluesky Handle", text: $sourceAccount)
             }
            HStack {
                Text("App password")
                Spacer(minLength: 10)
                TextField("Password", text: $appPassword)
            }
            HStack {
                Text("Targetaccount")
                TextField("Bluesky Handle", text: $targetAccountHandle)
           }
            HStack {
                Text("Limit")
                Spacer(minLength: 66)
                TextField("Max. 100", text: $limit)
                    .onChange(of: limit) {
                        if let i = Int(limit) {
                            iLimit = i
                        } else {
                            // error message
                        }
                    }
             }
            Button("Run") {
                var blueskyCrawler = BlueskyCrawler(sourceAccount: sourceAccount, targetAccount: targetAccountHandle, appPassword: appPassword, limit: iLimit)
                blueskyCrawler.run()
            }
        }
        .frame(width:250)
    }
}

#Preview {
    ControlPanel()
}
