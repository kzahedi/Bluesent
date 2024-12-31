//
//  UserDefaultsExtensions.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 31.12.24.
//

import Foundation

extension UserDefaults {

    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
    
    func boolValueAlternate(firstKey:String, alternateKey:String) -> Bool? {
        if valueExists(forKey: firstKey) == false && valueExists(forKey: alternateKey) == false {
            return nil
        }
        if valueExists(forKey: firstKey) {
            return self.bool(forKey: firstKey)
        }
        return self.bool(forKey: alternateKey)
    }
    
    func stringValueAlternate(firstKey:String, alternateKey:String) -> String? {
        if valueExists(forKey: firstKey) == false && valueExists(forKey: alternateKey) == false {
            return nil
        }
        if valueExists(forKey: firstKey) {
            return self.string(forKey: firstKey)
        }
        return self.string(forKey: alternateKey)
    }
    
    func intValueAlternate(firstKey:String, alternateKey:String) -> Int? {
        if valueExists(forKey: firstKey) == false && valueExists(forKey: alternateKey) == false {
            return nil
        }
        if valueExists(forKey: firstKey) {
            return self.integer(forKey: firstKey)
        }
        return self.integer(forKey: alternateKey)
    }
    
    func dateValueAlternate(firstKey:String, alternateKey:String) -> Date? {
        if valueExists(forKey: firstKey) == false && valueExists(forKey: alternateKey) == false {
            return nil
        }
        if valueExists(forKey: firstKey) {
            return (self.object(forKey: firstKey) as! Date)
        }
        return (self.object(forKey: alternateKey) as! Date)
    }

}
