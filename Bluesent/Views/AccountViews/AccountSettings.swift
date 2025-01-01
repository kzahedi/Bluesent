//
//  AccountSettings.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 31.12.24.
//

import Foundation
import SwiftUI

struct AccountSettings : View {
    private var did : String = ""
    private var account : Account
    
    @State var active : Bool = true
    @State var forceUpdateFeed : Bool = true
    @State var forceUpdateReply : Bool = true
    @State var forceUpdateSentiments : Bool = true
    @State var forceUpdate : Bool = true
    @State var date : Date = Date()
    @State var nrOfDays : String = ""
    @State var minDaysBeforeUpdate : Int = 0
    
    @State private var isFeedScraping: Bool = false
    @State private var isReplyTreeScraping: Bool = false
    @State private var isCalculatingSentiments: Bool = false
    @State private var isCountingReplies: Bool = false
    @State private var isCountingPostPerDay: Bool = false
    
    init(did:String) {
        self.did = did
        self.account = AccountStore.shared.getAccountBy(did: did)!
    }
    
    public func initialiseValues() {
        active = UserDefaults.standard.valueExists(forKey: "\(labelActiveAccount)_\(self.did)") ?
        UserDefaults.standard.bool(forKey: "\(labelActiveAccount)_\(self.did)") : true
        
        forceUpdateFeed = UserDefaults.standard.boolValueAlternate(
            firstKey: "\(labelForceUpdateFeed)_\(self.did)",
            alternateKey: labelForceUpdateFeed) ?? false
        
        forceUpdateReply = UserDefaults.standard.bool(forKey:"\(labelForceUpdateReplies)_\(self.did)")
        forceUpdateSentiments = UserDefaults.standard.bool(forKey: "\(labelForceUpdateSentiments)_\(self.did)")
        
        date = UserDefaults.standard.dateValueAlternate(
            firstKey: "\(labelScrapingDate)_\(self.did)",
            alternateKey: labelScrapingDate) ?? Date()
        
        minDaysBeforeUpdate = UserDefaults.standard.intValueAlternate(
            firstKey: "\(labelScrapingMinDaysForUpdate)_\(self.did)",
            alternateKey: labelScrapingMinDaysForUpdate) ?? 0
        
        nrOfDays = String(minDaysBeforeUpdate)
        
    }
    
    var body: some View {
        Form {
            Divider()
            Section {
                HStack {
                    DatePicker(selection: $date,
                               displayedComponents: [.date],
                               label: { Text("Earliest Date") })
                    .datePickerStyle(.field)
                    .onChange(of: date) {
                        let d = date.setToStartOfDay()
                        UserDefaults.standard
                            .set(d, forKey: account.scrapingDateLabel)
                    }
                }
                .padding()
            }
            Divider()
            Section {
                HStack {
                    TextField("Minimum days before\nreplies are scraped", text: $nrOfDays)
                        .onChange(of: nrOfDays) {
                            if let i = Int(nrOfDays) {
                                minDaysBeforeUpdate = i
                                if i < 0 {
                                    minDaysBeforeUpdate = 0
                                    nrOfDays = "0"
                                }
                            }
                            
                            UserDefaults.standard.set(minDaysBeforeUpdate,
                                                      forKey: account.scrapingDateLabel)
                        }
                }
                .padding()
            }
            Divider()
            //            Section{
            //                HStack {
            //                    Toggle(isOn: $active) {
            //                        Text("Active")
            //                    }
            //                    .onChange(of: active){
            //                        UserDefaults.standard.set(active, forKey:account.activeLabel)
            //                    }
            //                }
            
            HStack {
                Toggle(isOn: $forceUpdateFeed) {
                    Text("Force update of feed")
                }
                .onChange(of: forceUpdateFeed){
                    UserDefaults.standard.set(forceUpdateFeed,
                                              forKey: account.forceFeedUpdateLabel)
                }
            }
            
            HStack {
                Toggle(isOn: $forceUpdateReply) {
                    Text("Force update of reply trees")
                }
                .onChange(of: forceUpdateReply){
                    UserDefaults.standard.set(forceUpdateReply,
                                              forKey: account.forceReplyTreeUpdateLabel)
                }
            }
            
            HStack {
                Toggle(isOn: $forceUpdateSentiments) {
                    Text("Force update of sentiment analysis")
                }
                .onChange(of: forceUpdateSentiments){
                    UserDefaults.standard.set(forceUpdateSentiments,
                                              forKey: account.forceSentimentUpdateLabel)
                }
            }
        }
        Divider()
        Section {
            Grid(alignment:.trailing) {
                GridRow{
                    Text("Scrape Feed")
                        .gridColumnAlignment(.leading)
                    Button("Run") {
                        runFeedCrawler()
                    }
                    .disabled(isFeedScraping) // Disable button while scraping is in progress
                    if isFeedScraping {
                        Text("Running")
                    } else {
                        Text("")
                    }
                    
                }
                
                GridRow{
                    Text("Scrape Reply Trees")
                        .gridColumnAlignment(.leading)
                    Button("Run") {
                        runReplyTreeCrawler()
                    }
                    .disabled(isReplyTreeScraping) // Disable button while scraping is in progress
                    if isFeedScraping {
                        Text("Running")
                    } else {
                        Text("")
                    }
                }
            }
        }
        Divider()
        Section {
            Grid(alignment:.trailing) {
                GridRow{
                    Text("Analyse Reply Tree Depths")
                        .gridColumnAlignment(.leading)
                    Button("Run") {
                        countingReplies()
                    }
                    .disabled(isCountingReplies)
                    if isCountingReplies {
                        Text("Running")
                    } else {
                        Text("")
                    }
                }
                GridRow {
                    Text("Calculate Posts Per Day")
                        .gridColumnAlignment(.leading)
                    Button("Run") {
                        countingPostsPerDay()
                    }
                    .disabled(isCountingPostPerDay)
                    if isCountingPostPerDay  {
                        Text("Running")
                    } else {
                        Text("")
                    }
                }
            }
        }
        .padding(.bottom)
        .padding(.trailing)
        .onAppear() { initialiseValues() }
    }
    
    func runFeedCrawler() {
        isFeedScraping = true
        DispatchQueue.background(delay: 0.0, background: {
            account.scrapeFeed()
        }, completion: {
            isFeedScraping = false
        })
    }
    
    func runReplyTreeCrawler() {
        isReplyTreeScraping = true
        DispatchQueue.background(delay: 0.0, background: {
            account.scrapeReplyTrees()
        }, completion: {
            isReplyTreeScraping = false
        })
    }
    
    func countingReplies() {
        isCountingReplies = true
        DispatchQueue.background(delay: 0.0, background: {
            account.countReplies()
        }, completion: {
            isCountingReplies = false
        })
    }
    
    func countingPostsPerDay() {
        isCountingPostPerDay = true
        DispatchQueue.background(delay: 0.0, background: {
            account.countPostsPerDay()
        }, completion: {
            isCountingPostPerDay = false
        })
    }
    
}

#Preview{
    AccountSettings(did:"did:plc:42pjb4dy3p3ubiekmwpkthen")
}
