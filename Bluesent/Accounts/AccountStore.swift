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
        
        let names : [String] = UserDefaults.standard.stringArray(forKey: labelListOfAccounts) ?? []
        
        print(names)
        
        let dids : [String] = names
            .map{resolveDID(handle:$0) ?? ""}
            .filter { !$0.isEmpty }
        
        
        if accounts.isEmpty {
            for did in dids {
                let a = try Account(did:did)
                accounts.append(a)
            }
        } else {
            let available_dids = accounts.map { $0.did }
            let missing_dids = dids.filter { !available_dids.contains($0) }
            
            for did in missing_dids {
                let a = try Account(did:did)
                accounts.append(a)
            }
        }
        
    }
}
