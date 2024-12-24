//
//  UserSession.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//


class BlueSkyUserSession {
    static let shared = BlueSkyUserSession() // Singleton instance

    var accountName: String
    var accountDID: String
    var token: String

    private init() {
        // Initialize the user session
        accountName = ""
        accountDID = ""
        token = ""
    }

    public func set(accountName: String, accountDID: String, token: String) {
        self.accountName = accountName
        self.accountDID = accountDID
        self.token = token
    }
    
}
