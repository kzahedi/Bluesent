//
//  SessionState.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//
import Foundation

class SessionState : ObservableObject {
    static let shared = SessionState() // Singleton instance

    private var runScraper = false
    private var targetAccount : String = ""
    public var accountHandle: String = ""
    public var appPassword: String = ""
    public var accountDID: String = ""
    public var limit: Int = 100

    public var token: String = ""
    

    private init() { }
    
    public func setTargetAccount(handle: String) {
        print("Before: \(self.targetAccount)")
        self.targetAccount = handle
        print("After: \(self.targetAccount)")
//        objectWillChange.send()
    }
    
    public func getTargetAccount() -> String {
        return self.targetAccount
    }
    
    public func toggleRunScraper() {
        self.runScraper = !self.runScraper
    }
    
    public func getRunScraper() -> Bool {
        return self.runScraper
    }
    
    public func setAccountHandle(handle: String) {
        self.accountHandle = handle
    }
    
    public func getAccountHandle() -> String {
        return self.accountHandle
    }
    
    public func setAppPassword(password: String) {
        self.appPassword = password
    }
    
    public func getAppPassword() -> String {
        return self.appPassword
    }
    
    public func setAccountDID(did: String) {
        self.accountDID = did
    }
    
    public func getAccountDID() -> String {
        return self.accountDID
    }
    
    public func setLimit(limit: Int) {
        self.limit = limit
        print(self.limit)
    }
    
    public func getLimit() -> Int {
        return self.limit
    }
    
}
