//
//  CrawlerSettings.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 26.12.24.
//

import Foundation
import SwiftUI

struct GeneralCrawlerSettings : View {
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
            Divider()
            Section {
                HStack {
                    DatePicker(selection: $date,
                               displayedComponents: [.date],
                               label: { Text("Earliest Date") })
                    .datePickerStyle(.field)
                    .onChange(of: date) {
                        let d = date.toStartOfDay()
                        UserDefaults.standard.set(d, forKey: labelScrapingDate)
                    }
                    .onAppear() {
                        date = UserDefaults.standard.object(forKey: labelScrapingDate) as! Date
                    }
                }
                .padding()

                Divider()
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
                .padding(.top)
                .padding(.trailing)
                .padding(.leading)

                HStack {
                    TextField("Minimum days before", text: $nrOfDays)
                        .onChange(of: nrOfDays) {
                            if let i = Int(nrOfDays) {
                                iNrOfDays = i
                                if i < 0 { iNrOfDays = 0 }
                                UserDefaults.standard.set(iNrOfDays, forKey: labelScrapingMinDaysForUpdate)
                            } else {
                                // error message
                            }
                        }
                        .onAppear() {
                            iNrOfDays = UserDefaults.standard.integer(forKey: labelScrapingMinDaysForUpdate)
                            nrOfDays = String(iNrOfDays)
                        }
                }
                .padding(.bottom)
                .padding(.trailing)
                .padding(.leading)

                Divider()
                HStack {
                    Toggle(isOn: $updateFeed) {
                        Text("Force the update of the account feed")
                    }
                    .onChange(of: updateFeed) {
                        UserDefaults.standard.set(updateFeed, forKey: labelForceUpdateFeed)
                    }
                    .onAppear() {
                        updateFeed = UserDefaults.standard.bool(forKey: labelForceUpdateFeed)
                    }
                }
                .padding(.trailing)

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
                .padding(.trailing)
                .padding(.bottom)
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
            let d = date.toStartOfDay()
            UserDefaults.standard.set(d, forKey: labelScrapingDate)
        }
        updateReplies = UserDefaults.standard.bool(forKey: labelForceUpdateReplies)
        updateFeed = UserDefaults.standard.bool(forKey: labelForceUpdateFeed)
    }
}

#Preview{
    GeneralCrawlerSettings()
}
