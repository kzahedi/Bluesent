//
//  ListOfAccountsView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation
import SwiftUI

struct ListOfAccountsView: View {
    @State private var entries: [String] = []
    @State private var editingEntryIndex: Int? = nil
    @State private var isEditing: Bool = false // Track whether we're in "edit mode"

    var body: some View {
        VStack {
            List {
                ForEach(entries.indices, id: \.self) { index in
                    if editingEntryIndex == index {
                        // In-place editing using TextField
                        TextField("Edit Entry", text: Binding(
                            get: { entries[index] },
                            set: { newValue in entries[index] = newValue }
                        ), onCommit: {
                            editingEntryIndex = nil // Exit editing mode when committed
                            saveEntries()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        // Show normal text and allow double-click for editing
                        Text(entries[index])
                            .onTapGesture(count: 2) {
                                editingEntryIndex = index // Enter editing mode on double-click
                            }
                    }
                }
                .onDelete(perform: deleteEntry) // Enable swipe-to-delete
                .onMove(perform: moveEntry) // Enable drag-and-drop rearranging
            }
            .padding()
            .disabled(!isEditing) // Disable list interaction when not in edit mode

            // Buttons to toggle edit mode and add/remove entries
            HStack {
                Button(action: toggleEditMode) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                    Text(isEditing ? "Done" : "Edit")
                }

                Button(action: addEntry) {
                    Image(systemName: "plus")
                    Text("Add")
                }

                Button(action: deleteSelectedEntry) {
                    Image(systemName: "minus")
                    Text("Remove")
                        .foregroundColor(editingEntryIndex != nil ? .primary : .gray)
                }
                .disabled(editingEntryIndex == nil || !isEditing)

                Spacer() // Align buttons to the left
            }
            .padding()
        }
        .onAppear {
            loadEntries()
        }
    }

    // MARK: - Actions
    private func toggleEditMode() {
        isEditing.toggle() // Toggle the editing mode
    }

    private func addEntry() {
        entries.append("New Entry")
        saveEntries()
    }

    private func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveEntries()
    }

    private func deleteSelectedEntry() {
        if let index = editingEntryIndex {
            entries.remove(at: index)
            editingEntryIndex = nil // Exit editing mode
            saveEntries()
        }
    }

    private func moveEntry(from source: IndexSet, to destination: Int) {
        entries.move(fromOffsets: source, toOffset: destination)
        saveEntries()
    }

    // MARK: - Persistence
    private func loadEntries() {
        entries = UserDefaults.standard.array(forKey: "targetAccounts") as? [String] ?? []
    }

    private func saveEntries() {
        UserDefaults.standard.set(entries, forKey: "targetAccounts")
    }
}







#Preview {
    ListOfAccountsView()
}
