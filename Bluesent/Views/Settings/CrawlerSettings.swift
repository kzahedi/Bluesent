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
    @State var update: Bool = false

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
                        print("Setting date to \(d)")
                        UserDefaults.standard.set(d, forKey: "scrapingDate")
                    }
                    .onAppear() {
                        date = UserDefaults.standard.object(forKey: "scrapingDate") as! Date
                        print("Reading date \(date)")
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
                    
                    Toggle(isOn: $update) {
                        Text("Force update")
                    }
                        .onChange(of: update) {
                                UserDefaults.standard.set(update, forKey: "update")
                            }
                        .onAppear() {
                            update = UserDefaults.standard.bool(forKey: "update")
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
        
    }
}

#Preview{
    CrawlerSettings()
}
