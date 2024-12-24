//
//  BlueskyCrawler.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import Foundation

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}

struct HandleResponse: Codable {
    let did: String
}

struct TokenResponse: Codable {
    let accessJwt: String

    enum CodingKeys: String, CodingKey {
        case accessJwt = "accessJwt"
    }
}


class BlueskyCrawler {
    
    private let didURL = "https://bsky.social/xrpc/com.atproto.identity.resolveHandle"
    private let apiKeyURL = "https://bsky.social/xrpc/com.atproto.server.createSession"
    private let feedURL = "https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed"
    
    private var sourceAccount: String? = nil
    private var targetAccount: String? = nil
    private var appPassword: String? = nil
    private var limit: Int? = nil
    
    private var token: String? = nil
    
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
        
        let sourceDid: String? = resolveDID(handle: sourceAccount!)
        let targetDid: String? = resolveDID(handle: targetAccount!)
        
        if sourceDid == nil {
            print("Cannot resolve \(sourceAccount!)")
        } else {
            print("Source DID: \(sourceDid!)")
        }
        
        if targetDid == nil {
            print("Cannot resolve \(targetAccount!)")
        } else {
            print("Target DID: \(sourceDid!)")
        }
        
        let token : String? = getToken(sourceDID: sourceDid!, appPassword: appPassword!)
        
        if token == nil {
            print("Cannot get token")
        } else {
            print("Token: \(token!)")
        }
       
    }
    
   
    private func resolveDID(handle: String) -> String? {
        let group = DispatchGroup()
        let url = URL(string: "\(didURL)?handle=\(handle)")
        
        if url == nil {
            print("Not an URL: \(didURL)?handle=\(handle)")
            return nil
        }

        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        var returnValue : String? = nil

        group.enter()
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                print("Error resolving handle: \(error!)")
                group.leave()
            }

            if data == nil {
                print("No data received")
                group.leave()
            }

            // Log raw response for debugging
            if let jsonString = String(data: data!, encoding: .utf8) {
                print("Raw Handle Response: \(jsonString)")
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

                let handleResponse = try JSONDecoder().decode(HandleResponse.self, from: data!)
                returnValue = handleResponse.did
                group.leave()
            } catch {
                print("Error decoding handle response: \(error.localizedDescription)")
                group.leave()
            }
        }

        task.resume()
        group.wait()
        return returnValue
    }
    
    
    private func getToken(sourceDID: String, appPassword: String) -> String? {
        let group = DispatchGroup()
        let tokenPayload: [String: Any] = [
            "identifier": sourceDID,
            "password": appPassword
        ]

        guard let tokenData = try? JSONSerialization.data(withJSONObject: tokenPayload) else {
            print("Error creating JSON payload")
            return nil
        }

        var tokenRequest = URLRequest(url: URL(string: apiKeyURL)!)
        tokenRequest.httpMethod = "POST"
        tokenRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        tokenRequest.httpBody = tokenData

        print("Requesting token with DID: \(sourceDID) and Password")
        
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

            // Log the raw JSON response
            if let jsonString = String(data: data!, encoding: .utf8) {
                print("Raw Token Response: \(jsonString)")
            } else {
                print("Cannot decode JSON")
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


