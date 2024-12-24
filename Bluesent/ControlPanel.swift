//
//  ControlPanel.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import SwiftUI

struct ControlPanel: View {
    var body: some View {
        var showFileImporter: Bool = true
        VStack{
            Button {
                showFileImporter = true
            } label: {
                Label("Choose Configuration", systemImage: "doc.circle")
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let files):
                    files.forEach { file in
                        // gain access to the directory
                        let gotAccess = file.startAccessingSecurityScopedResource()
                        if !gotAccess { return }
                        // access the directory URL
                        // (read templates in the directory, make a bookmark, etc.)
                        handlePickedPDF(file)
                        // release access
                        file.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    // handle error
                    print(error)
                }
            }
            
        }
    }
}

#Preview {
    ControlPanel()
}
