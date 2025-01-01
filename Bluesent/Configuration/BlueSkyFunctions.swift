//
//  BlueSkyFunctions.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 31.12.24.
//

import Foundation

func resolveDID(handle: String) -> String? {
    let didURL = "https://bsky.social/xrpc/com.atproto.identity.resolveHandle"
    let group = DispatchGroup()
    let url = URL(string: "\(didURL)?handle=\(handle)")
    print(url)
    
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
            prettyPrintJSON(data: data!)
            print("Error decoding handle response: \(error.localizedDescription)")
            group.leave()
        }
    }
    
    task.resume()
    group.wait()
    return returnValue
}
