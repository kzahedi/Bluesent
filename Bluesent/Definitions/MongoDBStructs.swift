//
//  MongoDBStructs.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 27.12.24.
//
import Foundation



struct DailyStatsMDB : Codable, Identifiable {
    var id : UUID = UUID()
    var _id : String // Handle
    var posts_per_day : [PostsPerDayMDB]
}

struct PostsPerDayMDB : Codable, Identifiable {
    var id : UUID = UUID()
    var day: Date
    var count: Int
    
    init(day:Date, count:Int){
        self.day = day
        self.count = count
    }
}
