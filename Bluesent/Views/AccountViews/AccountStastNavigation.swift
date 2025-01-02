//
//  CrawlerSettings.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 26.12.24.
//

import Foundation
import SwiftUI

struct AccountStastNavigation: View {
    @ObservedObject var accountsStores = AccountStore.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach($accountsStores.accounts) { $account in
                    if account.did != nil {
                        NavigationLink(destination: AccountStatsView(did:account.did!)) {
                            if account.author == "N/A" {
                                Label("\(account.handle)", systemImage: "person.circle")
                            } else {
                                Label("\(account.author)", systemImage: "person.circle")
                            }
                        }
                        .padding(.trailing)
                        .padding(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight:.infinity)
        }
    }
}

#Preview{
    AccountStastNavigation()
}
