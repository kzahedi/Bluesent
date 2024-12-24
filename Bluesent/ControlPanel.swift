//
//  ControlPanel.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import SwiftUI

struct ControlPanel: View {
    var state : SessionState = .shared
    
    @State private var showingAlert = false
    
    @State private var limit: String = ""
    @State private var targetAccountHandle: String = ""
    @State private var appPassword: String = ""
    @State private var sourceAccount: String = ""
    
    @ObservedObject var sessionState: SessionState = .shared
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                Text("Account")
                Spacer(minLength: 47)
                TextField("Bluesky Handle", text: $sourceAccount)
                    .onChange(of: sourceAccount) {
                        sessionState.setAccountHandle(handle: sourceAccount)
                    }
             }
            HStack {
                Text("App password")
                Spacer(minLength: 10)
                TextField("Max. 100", text: $appPassword)
                    .onChange(of: appPassword) {
                        sessionState.setAppPassword(password: targetAccountHandle)
                    }
                
            }
            HStack {
                Text("Targetaccount")
                TextField("Bluesky Handle", text: $targetAccountHandle)
                    .onChange(of: targetAccountHandle) {
                        sessionState.setTargetAccount(handle: targetAccountHandle)
                    }
            }
            HStack {
                Text("Limit")
                Spacer(minLength: 66)
                TextField("Max. 100", text: $limit)
                    .onChange(of: limit) {
                        if let ilimit = Int(limit) {
                            sessionState.setLimit(limit: ilimit)
                        } else {
                            // error message
                        }
                    }
             }
            Button("Run") {
                state.toggleRunScraper()
            }
        }
        .frame(width:250)
    }
}

#Preview {
    ControlPanel()
}
