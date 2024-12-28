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
    
    public func postsPerDay() throws {
        let collection = try MongoDBHandler().posts
        do {
            let pipeline: [BSONDocument] = [
                [
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
                // Group by "handle" and "day"
                [
                    "$group": [
                        "_id": [
                            "handle": "$handle",
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
                        "_id.handle": 1
                    ]
                ]
            ]

            
            
            let cursor = try collection.aggregate(pipeline)
            for try result in cursor {
                print(result)
            }
        } catch {
            print("Error running aggregation: \(error)")
        }
        
    }
    
}
