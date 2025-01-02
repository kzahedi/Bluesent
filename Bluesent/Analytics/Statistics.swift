//
//  Statistics.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 28.12.24.
//

import Foundation
import NaturalLanguage
import MongoSwiftSync


struct DailyStats: Codable {
    var _id : String // Handle
    var postStats: [StatsEntry]?
    var replyStats: [StatsEntry]?
    var replyTreeStats: [StatsEntry]?
    var sentimentStats: [String:[StatsEntry]?]?
}

struct StatsEntry : Codable, Identifiable {
    var id : Date {day}
    var day: Date
    var values: [Double]?
    var sum: Double?
    var avg: Double?
    var stdDev: Double?
}

struct Statistics {
    
    func standardDeviation(_ numbers: [Double]) -> Double {
        let count = Double(numbers.count)
        guard count > 1 else { return 0 }
        
        let mean = numbers.reduce(0, +) / count
        let sumOfSquaredDifferences = numbers.map { pow($0 - mean, 2) }.reduce(0, +)
        return sqrt(sumOfSquaredDifferences / (count - 1))
    }
    
    public func countPostsPerDay(did:String) throws {
        let mongoDBHandler = try MongoDBHandler()
        var r : DailyStats? = try mongoDBHandler.statistics.findOne(["did":BSON(stringLiteral: did)])
        
        if r == nil {
            r = DailyStats(_id:did, postStats:nil, replyStats:nil, sentimentStats:nil)
        }
        
        let query : BSONDocument = ["did":BSON(stringLiteral: did)]
        let options = FindOptions(sort: ["createdAt": 1])
        let cursor = try mongoDBHandler.posts.find(query,options:options)
        
        var stats : [Date:StatsEntry] = [:]
        
        for element in cursor {
            let doc = try element.get()
            let day = doc.createdAt!.toStartOfDay()
            if stats.keys.contains(day) {
                var entry = stats[day]!
                if entry.sum == nil {
                    entry.sum! = 1.0
                } else {
                    entry.sum! += 1.0
                }
                stats[day] = entry
            } else {
                stats[day] = StatsEntry(day:day, values:nil, sum:1.0, avg:nil, stdDev:nil)
            }
        }
        
        var s =  Array(stats.values)
        s.sort{ (($0.day).compare($1.day)) == .orderedDescending }
        
        r!.postStats = s
        
        try mongoDBHandler.updateDailyStats(document: r!)
        
    }
    
    public func countReplies(did:String) throws {
        let mongoDBHandler = try MongoDBHandler()
        var r : DailyStats? = try mongoDBHandler.statistics.findOne(["did":BSON(stringLiteral: did)])
        
        if r == nil {
            r = DailyStats(_id:did, postStats:nil, replyStats:nil, sentimentStats:nil)
        }
        
        let query : BSONDocument = ["did":BSON(stringLiteral: did)]
        let options = FindOptions(sort: ["createdAt": 1])
        let cursor = try mongoDBHandler.posts.find(query,options:options)
        
        var stats : [Date:StatsEntry] = [:]
        
        for element in cursor {
            let doc = try element.get()
            let day = doc.createdAt!.toStartOfDay()
            let value = Double(doc.countedReplies!)
            if stats.keys.contains(day) {
                var entry = stats[day]!
                entry.values!.append(value)
                stats[day] = entry
            } else {
                stats[day] = StatsEntry(day:day, values:[value], sum:nil, avg:nil, stdDev:nil)
            }
        }
        
        for key in stats.keys {
            var s = stats[key]!
            s.sum = s.values!.reduce(0, +)
            s.avg = s.sum! / Double(s.values!.count)
            s.stdDev = standardDeviation(s.values!)
            stats[key] = s
        }
        
        var s =  Array(stats.values)
        s.sort{ (($0.day).compare($1.day)) == .orderedDescending }
        
        r!.replyStats = s
        
        try mongoDBHandler.updateDailyStats(document: r!)
        
    }
    
    public func countReplyTreeDepths(did:String) throws {
        let mongoDBHandler = try MongoDBHandler()
        var r : DailyStats? = try mongoDBHandler.statistics.findOne(["did":BSON(stringLiteral: did)])
        
        if r == nil {
            r = DailyStats(_id:did, postStats:nil, replyStats:nil, sentimentStats:nil)
        }
        
        let query : BSONDocument = ["did":BSON(stringLiteral: did)]
        let options = FindOptions(sort: ["createdAt": 1])
        let cursor = try mongoDBHandler.posts.find(query,options:options)
        
        var stats : [Date:StatsEntry] = [:]
        
        for element in cursor {
            let doc = try element.get()
            let day = doc.createdAt!.toStartOfDay()
            let value = Double(doc.countedRepliesDepth!)
            if stats.keys.contains(day) {
                var entry = stats[day]!
                entry.values!.append(value)
                stats[day] = entry
            } else {
                stats[day] = StatsEntry(day:day, values:[value], sum:nil, avg:nil, stdDev:nil)
            }
        }
        
        for key in stats.keys {
            var s = stats[key]!
            s.sum = s.values!.reduce(0, +)
            s.avg = s.sum! / Double(s.values!.count)
            s.stdDev = standardDeviation(s.values!)
            stats[key] = s
        }
        
        var s =  Array(stats.values)
        s.sort{ (($0.day).compare($1.day)) == .orderedDescending }
        
        r!.replyTreeStats = s
        
        try mongoDBHandler.updateDailyStats(document: r!)
    }
    
    public func collectPostSentiments(did:String) throws {
        let mongoDBHandler = try MongoDBHandler()
        var r : DailyStats? = try mongoDBHandler.statistics.findOne(["did":BSON(stringLiteral: did)])
        
        if r == nil {
            r = DailyStats(_id:did, postStats:nil, replyStats:nil, sentimentStats:nil)
        }
       
        let values = try mongoDBHandler.posts.distinct(fieldName: "sentiment.0.model")
        let taggerNames = values.map{$0.stringValue!}
        
        print(taggerNames)
        
        for tagger in taggerNames {
            
            var stats : [Date:StatsEntry] = [:]
           
            let q : BSONDocument = ["did":BSON(stringLiteral: did), "sentiment.0.model":BSON(stringLiteral: tagger)]
            let options = FindOptions(sort: ["createdAt": 1])
            let cursor = try mongoDBHandler.posts.find(q, options:options)
            
            
            for element in cursor {
                let doc = try element.get()
                let day = doc.createdAt!.toStartOfDay()
                let values = doc.sentiment!
                let value = values.filter{$0.model == tagger}.first!
                if stats.keys.contains(day) {
                    var entry = stats[day]!
                    entry.values!.append(value.score!)
                    stats[day] = entry
                } else {
                    stats[day] = StatsEntry(day:day, values:[value.score!], sum:nil, avg:nil, stdDev:nil)
                }
            }
            
            for key in stats.keys {
                var s = stats[key]!
                s.sum = s.values!.reduce(0, +)
                s.avg = s.sum! / Double(s.values!.count)
                s.stdDev = standardDeviation(s.values!)
                stats[key] = s
            }
            
            var s =  Array(stats.values)
            s.sort{ (($0.day).compare($1.day)) == .orderedDescending }
            
            if r!.sentimentStats == nil {
                r!.sentimentStats = [:]
            }
            r!.sentimentStats![tagger] = s
             
            try mongoDBHandler.updateDailyStats(document: r!)
            
        }
        
    }
}
