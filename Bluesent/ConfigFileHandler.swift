//
//  ConfigFileHandler.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import Foundation
import Yams


func readConfigFile(filename: String) throws -> [String: String] {
    let configFileURL = Bundle.main.url(forResource: "config", withExtension: "yaml")!
    let data = try Data(contentsOf: configFileURL)
    let yaml: [String: Any]? = try Yams.load(yaml:filename) as? [String: Any]
    let config: [String: String] = yaml!.mapValues { $0 as! String }
    return config
}
