//
//  ConfigFileHandler.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import Foundation
import Yams


func readConfigFile(filename: String) throws -> (String, String) {
    var yamlString = ""
    do {
        yamlString = try String(contentsOfFile: filename, encoding: .utf8)
    } catch {
        print(error)
    }
    let yamlData = try Yams.load(yaml: yamlString) as? [String: Any]
        
    let accountHandle = yamlData?["handle"] as? String ?? ""
    let appPassword = yamlData?["password"] as? String ?? ""

    return (accountHandle, appPassword)
}
