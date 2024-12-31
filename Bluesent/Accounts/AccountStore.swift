//
//  AnalyseAccount.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 31.12.24.
//

import Foundation

public class AccountStore : ObservableObject {
    
    static let shared = AccountStore()
    
    public var accounts: [Account] = []
    
    private init() {
        do {
            let _ = try updateAccountList()
        } catch {
            print(error)
        }
        
        for account in self.accounts {
            account.prettyPrint()
        }
    }
    
    
    public func updateAccountList() throws {
        
        var handles : [String] = UserDefaults.standard.stringArray(forKey: labelListOfAccounts) ?? []
        
        handles = handles.filter { !$0.isEmpty }
        
        if accounts.isEmpty {
            for handle in handles {
                let a = try Account(handle:handle)
                accounts.append(a)
            }
        } else {
            let available_handles = accounts.map { $0.handle }
            let missing_handles = handles.filter { !available_handles.contains($0) }
            
            for handle in missing_handles {
                let a = try Account(handle:handle)
                accounts.append(a)
            }
        }
        
    }
}
