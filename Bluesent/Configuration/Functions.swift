//
//  Functions.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 26.12.24.
//

import Foundation

func prettyPrintJSON(data: Data) {
    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
       let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
       let prettyString = String(data: prettyData, encoding: .utf8) {
        print("Raw Response:\n\(prettyString)")
    }
}

