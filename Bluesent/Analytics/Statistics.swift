//
//  Statistics.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 28.12.24.
//

import Foundation
import NaturalLanguage
import MongoSwiftSync

struct Statistics {
    
    public func postsPerDayFor(did:String) throws {
        let mongoDBHandler = try MongoDBHandler()
        let collection = mongoDBHandler.posts
        do {
            let pipeline: [BSONDocument] = [
                [
                    "$match": ["did": BSON(stringLiteral:did)]
                ],[
                    "$addFields": [
                        "formattedCreatedAt": [
                            "$substrBytes": [
                                "$createdAt", // original field
                                0,            // start at the beginning
                                10            // extract the first 10 characters (yyyy-mm-dd)
                            ]
                        ]
                    ]
                ],
                // Convert the "createdAt" string to a Date object
                [
                    "$addFields": [
                        "createdAtDate": [
                            "$dateFromString": [
                                "dateString": "$formattedCreatedAt",
                                "format": "%Y-%m-%d", // Explicitly include the 'Z'
                                "timezone": "UTC" // Handle the timezone properly
                            ]
                        ]
                    ]
                ],
                // Ensure the date conversion was successful and truncate to the day
                [
                    "$addFields": [
                        "day": [
                            "$cond": [
                                "if": ["$ne": ["$createdAtDate", BSON.null]],
                                "then": ["$dateTrunc": ["date": "$createdAtDate", "unit": "day"]],
                                "else": BSON.null
                            ]
                        ]
                    ]
                ],
                // Group by "did" and "day"
                [
                    "$group": [
                        "_id": [
                            "did": "$did",
                            "day": "$day"
                        ],
                        "count": ["$sum": 1]
                    ]
                ],
                // Filter out results where "day" is null
                [
                    "$match": [
                        "_id.day": ["$ne": BSON.null]
                    ]
                ],
                // Sort the results
                [
                    "$sort": [
                        "_id.day": 1,
                        "_id.did": 1
                    ]
                ]
            ]
            
            var results : [String: DailyStatsMDB] = [:]
            
            let cursor = try collection.aggregate(pipeline)
            for try result in cursor {
                let doc = try result.get()
                let did = doc["_id"]!.documentValue!["did"]!.stringValue!
                let day = doc["_id"]!.documentValue!["day"]!.dateValue!
                let count = doc["count"]!.toInt()!
                let ppd = PostsPerDayMDB(day:day, count:count)
                if results.keys.contains(did) == false {
                    results[did] = DailyStatsMDB(_id:did, posts_per_day: [])
                }
                results[did]!.posts_per_day.append(ppd)
            }
            
            for did in results.keys{
                var ds = results[did]
                ds!.posts_per_day
                    .sort{ (($0.day).compare($1.day)) == .orderedDescending }
                try mongoDBHandler.updateDailyStats(document:ds!)
            }
                    
        } catch {
            print("Error running aggregation: \(error)")
        }
        
    }
    
}
