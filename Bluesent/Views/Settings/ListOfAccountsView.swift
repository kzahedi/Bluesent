//
//  ListView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation
import SwiftUI

public struct ListOfAccountsView : View {
    
    @State private var listOfAccounts : [String] = [];
    @State private var newTargetAccount: String = ""
    
    
    public var body: some View {
        VStack{
            List {
                ForEach(listOfAccounts, id: \.self) { account in
                    Text(account)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            }
            HStack{
                TextField("Add Account", text: $newTargetAccount)
                    .frame(width: 200)
                Button("Add") {
                    listOfAccounts.append(newTargetAccount)
                    newTargetAccount = ""
                }
                Spacer()
            }
        }
        .onAppear {
            loadEntries()
        }
 
    }
    
    func move(from source: IndexSet, to destination: Int) {
        listOfAccounts.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(offsets: IndexSet) {
        listOfAccounts.remove(atOffsets: offsets)
    }
    
    private func loadEntries() {
        listOfAccounts = UserDefaults.standard.array(forKey: "targetAccounts") as? [String] ?? []
    }


}

#Preview {
    ListOfAccountsView()
}
