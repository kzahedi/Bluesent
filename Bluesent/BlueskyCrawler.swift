//
//  BlueskyCrawler.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import Foundation


class BlueskyCrawler {
    
    private var sourceAccount: String? = nil
    private var targetAccount: String? = nil
    private var appPassword: String? = nil
    private var limit: Int? = nil
    
    init(sourceAccount: String, targetAccount: String, appPassword: String, limit: Int) {
        self.sourceAccount = sourceAccount
        self.targetAccount = targetAccount
        self.appPassword = appPassword
        self.limit = limit
    }
    
    deinit {
        print("Bluesky crawler deinit")
    }
    
    public func run() {
        var errorMsg : String = ""
        if self.sourceAccount == nil || self.sourceAccount!.isEmpty{
            errorMsg += "Source account is missing.\n"
        }
        if self.targetAccount == nil || self.targetAccount!.isEmpty {
            errorMsg += "Target account is missing.\n"
        }
        if self.appPassword == nil || self.appPassword!.isEmpty {
            errorMsg += "App password is missing.\n"
        }
        if self.limit == nil {
            errorMsg += "Limit is missing.\n"
        }
        if self.limit! <= 0 || self.limit! > 100 {
            errorMsg += "Limit must be between 1 and 100.\n"
        }
        
        if errorMsg.isEmpty == false {
            print("Error: \(errorMsg)")
            return
        }
        
        print("Running Scraper with following parameters")
        print("  Source account: \(self.sourceAccount!)")
        print("  Target account: \(self.targetAccount!)")
        print("  App password:   \(self.appPassword!)")
        print("  Limit:          \(self.limit!)")
    }
    
}

    
