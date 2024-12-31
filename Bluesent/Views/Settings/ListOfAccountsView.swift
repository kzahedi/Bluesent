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
                .padding(.bottom)
            }
            HStack{
                TextField("Add Account", text: $newTargetAccount)
                    .frame(width: 200)
                Button("Add") {
                    let target = newTargetAccount.replacingOccurrences(
                        of: "\\r?\\n",
                        with: "",
                        options: .regularExpression
                    )
                    listOfAccounts.append(target)
                    newTargetAccount = ""
                    saveEntries()
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
        saveEntries()
    }
    
    func delete(offsets: IndexSet) {
        listOfAccounts.remove(atOffsets: offsets)
        saveEntries()
    }
    
    private func loadEntries() {
        listOfAccounts = UserDefaults.standard.array(forKey: labelListOfAccounts) as? [String] ?? []
    }

    private func saveEntries() {
        UserDefaults.standard.set(listOfAccounts, forKey: labelListOfAccounts)
    }

}

#Preview {
    ListOfAccountsView()
}
