//
//  ContentView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 23.12.24.
//

import Foundation
import SwiftUI
import Charts

struct PostsPerDayView: View {
    @State var data : [DailyStatsMDB]? = nil
    
    var body: some View {
        ScrollView{
            if data != nil && data!.count > 0 {
                ForEach (data!) {d in
                    
                    plotView(d)
                        .padding()
                    titleView(d)
                        .padding()
                        .offset(y:-150)
                }
            } else {
                Text("no data")
            }
        }
        .background(Color.black)
        .frame(maxWidth: 1000)
        .onAppear(){
            do {
                try updateData()
            } catch {
                print(error)
            }
        }
    }
    
    private func updateData() throws {
        print("Reading data")
        let mongoDB = try MongoDBHandler()
        data = try mongoDB.getPostsPerDay()
        print("Done reading data: (\(data?.count ?? 0))")
    }
    
    private func plotView(_ d: DailyStatsMDB) -> some View {
        VStack(alignment: .leading){
            Chart {
                ForEach(d.posts_per_day) { dataPoint in
                    BarMark(x: .value("Month", dataPoint.day, unit:.day),
                            y: .value("Count", dataPoint.count))
                }
            }
        }
        .frame(maxWidth: 1000, maxHeight: 200)
    }
    
    private func titleView(_ d: DailyStatsMDB) -> some View {
        HStack(alignment: .top){
            Text(d._id)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: 1000, maxHeight: 200, alignment: .leading)
    }
    
}

#Preview {
    PostsPerDayView()
}
