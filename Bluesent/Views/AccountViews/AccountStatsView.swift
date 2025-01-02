//
//  ContentView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 23.12.24.
//

import Foundation
import SwiftUI
import Charts

struct PostStatsDataPoint : Codable, Identifiable {
    var id : UUID = UUID()
    var day: Date
    var count: Int
}

struct AccountStatsView: View {
    var did:String = ""
    var accountStore : AccountStore = AccountStore.shared
    var account : Account? = nil
    
    @State var data : DailyStats? = nil
    @State var firstDay : Date? = nil
    @State var maxPostsPerDay : Int = 0
    @State var currentZoom = 0.0
    @State var totalZoom = 1.0
    @State var offset = CGSize.zero
    @State var isDragging = false

    
    init(did: String) {
        self.did = did
        self.account = accountStore.accounts.first { $0.did == did }
        do { try updateData() } catch { print(error) }
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if data != nil {
                VStack{
                    VStack(alignment: .leading){
                        let lst = data!.postStats!.map {
                            PostStatsDataPoint(id:UUID(), day: $0.day, count: Int($0.sum ?? 0))
                        }
                        GroupBox("Number of posts") {
                            Chart {
                                ForEach(lst) { dataPoint in
                                    BarMark(x: .value("Month", dataPoint.day, unit:.day),
                                            y: .value("Count", dataPoint.count))
                                }
                            }
                            .chartXScale(domain: firstDay!...Date())
                        }
                    }
                    .frame(width:800, height: 100)
                    .padding()
                    
                    
                    VStack(alignment: .leading){
                        let lst = data!.replyStats!.map {
                            PostStatsDataPoint(id:UUID(), day: $0.day, count: Int($0.sum ?? 0))
                        }
                        GroupBox("Sum of replies") {
                            Chart {
                                ForEach(lst) { dataPoint in
                                    BarMark(x: .value("Month", dataPoint.day, unit:.day),
                                            y: .value("Count", dataPoint.count))
                                }
                            }
                            .chartXScale(domain: firstDay!...Date())
                            .foregroundStyle(Color(.orange))
                        }
                        
                    }
                    .frame(width:800, height: 100)
                    .padding()
                    
                    VStack(alignment: .leading){
                        let lst = data!.replyTreeStats!.map {
                            PostStatsDataPoint(id:UUID(), day: $0.day, count: Int($0.avg ?? 0))
                        }
                        GroupBox("Average number of replies") {
                            Chart {
                                ForEach(lst) { dataPoint in
                                    BarMark(x: .value("Month", dataPoint.day, unit:.day),
                                            y: .value("Count", dataPoint.count))
                                }
                            }
                            .chartXScale(domain: firstDay!...Date())
                            .foregroundStyle(Color(.purple))
                        }
                        
                    }
                    .frame(width:800, height: 100)
                    .padding()

                    VStack(alignment: .leading){
                        let lst = data!.replyTreeStats!.map {
                            PostStatsDataPoint(id:UUID(), day: $0.day, count: Int($0.avg ?? 0))
                        }
                        GroupBox("Average Sentiment per Post (NLTagger)") {
                            Chart {
                                ForEach(lst) { dataPoint in
                                    BarMark(x: .value("Month", dataPoint.day, unit:.day),
                                            y: .value("Count", dataPoint.count))
                                }
                            }
                            .chartXScale(domain: firstDay!...Date())
                            .foregroundStyle(Color(.purple))
                        }
                        
                    }
                    .frame(width:800, height: 100)
                    .padding()


                }
                .scaleEffect(currentZoom + totalZoom)
                .offset(offset)
                .gesture(MagnifyGesture()
                    .onChanged { value in
                        currentZoom = value.magnification - 1
                    }
                    .onEnded { value in
                        totalZoom += currentZoom
                        currentZoom = 0
                    })
                .accessibilityZoomAction { action in
                    if action.direction == .zoomIn {
                        totalZoom += 1
                    } else {
                        totalZoom -= 1
                    }
                }
                .padding()

            }

        }
        .onAppear { do { try updateData() } catch { print(error) } }
    }

//                VStack (alignment: .leading) {
//                    Text(handle)
//                        .font(.headline)
//                        .fontWeight(.medium)
//                        .foregroundColor(Color.white)
//                        .multilineTextAlignment(.leading)
//                }
//        .background(Color.black)
//        .frame(minWidth: 800, minHeight: 400)
    
    private func updateData() throws {
        let mongoDB = try MongoDBHandler()
        data = try mongoDB.getPostsPerDay(did:did)
        firstDay = self.account!.getScrapingDate()
    }
}

#Preview {
    AccountStatsView(did:"did:plc:42pjb4dy3p3ubiekmwpkthen")
}
