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
    
    @State var active : Bool = true
    @State var forceUpdateFeed : Bool = true
    @State var forceUpdateReply : Bool = true
    @State var forceUpdateSentiments : Bool = true
    @State var forceUpdate : Bool = true
    @State var date : Date = Date()
    @State var nrOfDays : String = ""
    @State var minDaysBeforeUpdate : Int = 0

    init(did:String) {
        self.did = did
        
        initialiseValues()
        
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
    
    public func storeValues() {
        if let i = Int(nrOfDays) {
            minDaysBeforeUpdate = i
            if i < 0 {
                minDaysBeforeUpdate = 0
                nrOfDays = "0"
            }
        }
        
        UserDefaults.standard.set($active, forKey:"\(labelActiveAccount)_\(self.did)")
        UserDefaults.standard.set($forceUpdateFeed, forKey: "\(labelForceUpdateFeed)_\(self.did)")
        UserDefaults.standard.set($forceUpdateReply, forKey: "\(labelForceUpdateReplies)_\(self.did)")
        UserDefaults.standard.set($forceUpdateSentiments, forKey: "\(labelForceUpdateSentiments)_\(self.did)")
        UserDefaults.standard.set($minDaysBeforeUpdate, forKey: "\(labelScrapingMinDaysForUpdate)_\(self.did)")
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
                        UserDefaults.standard.set(d, forKey: "\(labelScrapingDate)_\(self.did)")
                    }
                }
                .padding()
            }
            Divider()
            Section {
                HStack {
                    TextField("Minimum days before", text: $nrOfDays)
                        .onChange(of: nrOfDays) { storeValues() }
                }
            }
            .padding()
            Divider()
            Section{
                HStack {
                    Toggle(isOn: $active) {
                        Text("Active")
                    }
                }
                .onChange(of: active){ storeValues() }
                
                HStack {
                    Toggle(isOn: $forceUpdateFeed) {
                        Text("Force update of feed")
                    }
                }
                .onChange(of: active){ storeValues() }
                
                HStack {
                    Toggle(isOn: $forceUpdateReply) {
                        Text("Force update of reply trees")
                    }
                }
                .onChange(of: active){ storeValues() }
                
                HStack {
                    Toggle(isOn: $forceUpdateSentiments) {
                        Text("Force update of sentiment analysis")
                    }
                }
                .onChange(of: active){ storeValues() }
            }
            Divider()
        }
        .onAppear { initialiseValues() }
    }
}


#Preview{
    AccountSettings(did:"did:plc:42pjb4dy3p3ubiekmwpkthen")
}
