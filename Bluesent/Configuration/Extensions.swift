//
//  UserDefaultsExtension.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 26.12.24.
//

import Foundation

extension UserDefaults {

    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }

}

extension Date {

    func setToStartOfDay() -> Date
    {
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        components.minute = 0
        components.second = 0
        components.hour = 0

        return calendar.date(from: components)!
    }
    
    func toCursor() -> String {
        return ISO8601DateFormatter().string(from: self)
    }
    
    func isXDaysAgo(x:Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let xDaysAgo = calendar.date(byAdding: .day, value: -x, to: now)
        if xDaysAgo == nil { return false }
        return self < xDaysAgo!
    }
}
