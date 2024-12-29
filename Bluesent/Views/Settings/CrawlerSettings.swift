//
//  CrawlerSettings.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 26.12.24.
//

import Foundation
import SwiftUI

struct CrawlerSettings: View {
    private let maxLimit : Int = 100
    @State var date: Date = Date()
    @State var iLimit: Int = 100
    @State var iNrOfDays: Int = 2
    @State var limit: String = "100"
    @State var nrOfDays: String = "2"
    @State var updateFeed: Bool = false
    @State var updateReplies: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    DatePicker(selection: $date,
                               displayedComponents: [.date],
                               label: { Text("Earliest Date") })
                    .datePickerStyle(.field)
                    .onChange(of: date) {
                        let d = date.setToStartOfDay()
                        UserDefaults.standard.set(d, forKey: labelScrapingDate)
                    }
                    .onAppear() {
                        date = UserDefaults.standard.object(forKey: labelScrapingDate) as! Date
                    }
                }
                
                HStack {
                    TextField("Scraping Batch Size", text: $limit)
                        .onChange(of: limit) {
                            if let i = Int(limit) {
                                iLimit = i
                                if i > maxLimit { iLimit = maxLimit}
                                if i < 0 { iLimit = 0 }
                                UserDefaults.standard.set(iLimit, forKey: labelScrapingBatchSize)
                            } else {
                                // error message
                            }
                        }
                        .onAppear() {
                            iLimit = UserDefaults.standard.integer(forKey: labelScrapingBatchSize)
                            limit = String(iLimit)
                        }
                }
                
                HStack {
                    TextField("Auto udpate days", text: $nrOfDays)
                        .onChange(of: nrOfDays) {
                            if let i = Int(nrOfDays) {
                                iNrOfDays = i
                                if i < 0 { iNrOfDays = 0 }
                                UserDefaults.standard.set(iNrOfDays, forKey: labelScrapingAutoUpdateDays)
                            } else {
                                // error message
                            }
                        }
                        .onAppear() {
                            iNrOfDays = UserDefaults.standard.integer(forKey: labelScrapingAutoUpdateDays)
                            nrOfDays = String(iNrOfDays)
                        }
                }
                
                HStack {
                    Toggle(isOn: $updateFeed) {
                        Text(labelForceUpdateFeed)
                    }
                    .onChange(of: updateFeed) {
                        UserDefaults.standard.set(updateFeed, forKey: labelForceUpdateFeed)
                    }
                    .onAppear() {
                        updateFeed = UserDefaults.standard.bool(forKey: labelForceUpdateFeed)
                    }
                }
                
                HStack {
                    Toggle(isOn: $updateReplies) {
                        Text("Force update replies")
                    }
                    .onChange(of: updateReplies) {
                        UserDefaults.standard.set(updateReplies, forKey: labelForceUpdateReplies)
                    }
                    .onAppear() {
                        updateReplies = UserDefaults.standard.bool(forKey: labelForceUpdateReplies)
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
    CrawlerSettings()
}
