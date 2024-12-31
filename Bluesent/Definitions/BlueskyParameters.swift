//
//  BlueskyParameters.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 29.12.24.
//

import Foundation

struct HandleResponse: Codable {
    let did: String
}

struct TokenResponse: Codable {
    let accessJwt: String
    
    enum CodingKeys: String, CodingKey {
        case accessJwt = "accessJwt"
    }
}

struct BlueskyParameters {
    public var sourceAccount: String = ""
    public var appPassword: String = ""
    public var valid : Bool = false
    public var sourceDID : String? = nil
    public var token : String? = nil
    public var limit = 0
    public var firstDate = Date()
     
    init() {
        var errorMsg : String = ""
        let sa = Credentials.shared.getUsername()
        let ap = Credentials.shared.getPassword()
        
        self.limit = UserDefaults.standard.integer(forKey: labelScrapingBatchSize)
        self.firstDate = UserDefaults.standard.object(forKey: labelScrapingDate) as! Date
       
        if sa == nil || sa!.isEmpty{
            errorMsg += "Source account is missing.\n"
        } else {
            self.sourceAccount = sa!
            self.sourceDID = resolveDID(handle: sa!)
        }
        
        if ap == nil || ap!.isEmpty {
            errorMsg += "App password is missing.\n"
        } else {
            self.appPassword = ap!
        }
        
        if self.limit <= 0 || self.limit > 100 {
            errorMsg += "Limit must be between 1 and 100.\n"
        }
        
        if errorMsg.isEmpty == false {
            print("Error: \(errorMsg)")
            return
        }
        
        self.token = getToken()
        if token == nil {
            print("Error receiving token")
            return
        }
        
        self.valid = true
    }
    

    
    public func getToken() -> String? {
        if self.sourceDID == nil || self.sourceDID!.isEmpty {
            return nil
        }
        let apiKeyURL = "https://bsky.social/xrpc/com.atproto.server.createSession"
        let group = DispatchGroup()
        let tokenPayload: [String: Any] = [
            "identifier": self.sourceDID!,
            "password": Credentials.shared.getPassword() ?? ""
        ]
        
        guard let tokenData = try? JSONSerialization.data(withJSONObject: tokenPayload) else {
            print("Error creating JSON payload")
            return nil
        }
        
        var tokenRequest = URLRequest(url: URL(string: apiKeyURL)!)
        tokenRequest.httpMethod = "POST"
        tokenRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        tokenRequest.httpBody = tokenData
        
        var returnValue : String? = nil
        
        group.enter()
        let tokenTask = URLSession.shared.dataTask(with: tokenRequest) { data, response, error in
            if let error = error {
                print("Error getting token: \(error)")
                group.leave()
            }
            
            if data == nil {
                print("No data received")
                group.leave()
            }
            
            do {
                // Check for error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    print("Error: \(errorResponse.error)")
                    if let message = errorResponse.message {
                        print("Message: \(message)")
                    }
                    group.leave()
                }
                
                // Decode the token response
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data!)
                returnValue = tokenResponse.accessJwt
                group.leave()
            } catch {
                print("Error decoding token response: \(error)")
                group.leave()
            }
        }
        tokenTask.resume()
        group.wait()
        return returnValue
    }
}
