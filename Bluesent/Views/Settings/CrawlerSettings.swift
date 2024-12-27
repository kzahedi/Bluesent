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
    @State var limit: String = "100"
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
                        UserDefaults.standard.set(d, forKey: "scrapingDate")
                    }
                    .onAppear() {
                        date = UserDefaults.standard.object(forKey: "scrapingDate") as! Date
                    }
                }
                
                HStack {
                    TextField("Scraping Batch Size", text: $limit)
                        .onChange(of: limit) {
                            if let i = Int(limit) {
                                iLimit = i
                                if i > maxLimit { iLimit = maxLimit}
                                if i < 0 { iLimit = 0 }
                                UserDefaults.standard.set(iLimit, forKey: "limit")
                            } else {
                                // error message
                            }
                        }
                        .onAppear() {
                            iLimit = UserDefaults.standard.integer(forKey: "limit")
                            limit = String(iLimit)
                        }
                }
                
                HStack {
                    Toggle(isOn: $updateFeed) {
                        Text("Force update feed")
                    }
                    .onChange(of: updateFeed) {
                        UserDefaults.standard.set(updateFeed, forKey: "update feed")
                    }
                    .onAppear() {
                        updateFeed = UserDefaults.standard.bool(forKey: "update feed")
                    }
                }
                
                HStack {
                    Toggle(isOn: $updateReplies) {
                        Text("Force update replies")
                    }
                    .onChange(of: updateReplies) {
                        UserDefaults.standard.set(updateReplies, forKey: "update replies")
                    }
                    .onAppear() {
                        updateReplies = UserDefaults.standard.bool(forKey: "update replies")
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
        if UserDefaults.standard.valueExists(forKey: "limit") {
            let v : Int = UserDefaults.standard.integer(forKey: "limit")
            iLimit = v
            if iLimit > maxLimit { iLimit = maxLimit}
            if iLimit < 0 { iLimit = 0}
            limit = String(v)
        } else {
            UserDefaults.standard.set(iLimit, forKey: "limit")
        }
        if UserDefaults.standard.valueExists(forKey: "scrapingDate") {
            let d : Date = UserDefaults.standard.object(forKey: "scrapingDate") as! Date
            date = d
        } else {
            let d = date.setToStartOfDay()
            UserDefaults.standard.set(d, forKey: "scrapingDate")
        }
        updateReplies = UserDefaults.standard.bool(forKey: "update replies")
        updateFeed = UserDefaults.standard.bool(forKey: "update feed")
    }
}

#Preview{
    CrawlerSettings()
}
