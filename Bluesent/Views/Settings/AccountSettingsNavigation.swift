//
//  CrawlerSettings.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 26.12.24.
//

import Foundation
import SwiftUI

struct AccountSettingsNavigation: View {
    @ObservedObject var accountsStores = AccountStore.shared
    private let maxLimit : Int = 100
    @State var date: Date = Date()
    @State var iLimit: Int = 100
    @State var iNrOfDays: Int = 2
    @State var limit: String = "100"
    @State var nrOfDays: String = "2"
    @State var updateFeed: Bool = false
    @State var updateReplies: Bool = false

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: GeneralCrawlerSettings()){
                    Label("General", systemImage: "arrow.2.circlepath")
                }
                .padding(.bottom)
                
                ForEach($accountsStores.accounts) { $account in
                    NavigationLink(destination: Text(account.author)) {
                        Label("\(account.handle)", systemImage: "arrow.2.circlepath")
                    }
                    .padding(.bottom)
                }
            }
        }
        
        .frame(maxWidth: .infinity, maxHeight:.infinity)
        .onAppear() {
            initialiseValues()
        }
    }
    
    private func initialiseValues() {
        if UserDefaults.standard.valueExists(forKey: labelScrapingBatchSize) {
            let v : Int = UserDefaults.standard.integer(forKey: labelScrapingBatchSize)
            iLimit = v
            if iLimit > maxLimit { iLimit = maxLimit}
            if iLimit < 0 { iLimit = 0}
            limit = String(v)
        } else {
            UserDefaults.standard.set(iLimit, forKey: labelScrapingBatchSize)
        }
        if UserDefaults.standard.valueExists(forKey: labelScrapingDate) {
            let d : Date = UserDefaults.standard.object(forKey: labelScrapingDate) as! Date
            date = d
        } else {
            let d = date.setToStartOfDay()
            UserDefaults.standard.set(d, forKey: labelScrapingDate)
        }
        updateReplies = UserDefaults.standard.bool(forKey: labelForceUpdateReplies)
        updateFeed = UserDefaults.standard.bool(forKey: labelForceUpdateFeed)
    }
}

#Preview{
 AccountSettingsNavigation()
}
