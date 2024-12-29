//
//  ContentView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 23.12.24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack(alignment: .top){
            
            VStack(alignment:.leading) {
                Text("Hello, world!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                
                HStack {
                    Text(/*@START_MENU_TOKEN@*/"Placeholder"/*@END_MENU_TOKEN@*/)
                        .font(.subheadline)
                    Text("Joshua Tree National Park")
                        .font(.subheadline)
                    Spacer()
                        .frame(width: 100.0, height: 1.0)
                    Text("California")
                        .font(.subheadline)
                }
            }
            .padding()
            .frame(maxWidth: 750, maxHeight: 500)
        }
        
    }
}

#Preview {
    ContentView()
}
