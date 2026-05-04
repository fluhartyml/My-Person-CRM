import SwiftUI
import SwiftData
import Contacts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrackedPerson.displayName) private var people: [TrackedPerson]

    @State private var contactsStore = ContactsStore()
    @State private var showingPicker = false
    @State private var showingManualEntry = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            Group {
                if people.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(people) { person in
                            NavigationLink(destination: PersonDetailView(person: person)) {
                                PersonRow(person: person)
                            }
                        }
                        .onDelete(perform: deletePeople)
                    }
                }
            }
            .navigationTitle("My Person CRM")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { addTapped() } label: {
                        Label("Add Person", systemImage: "person.crop.circle.badge.plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button { showingAbout = true } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showingPicker) {
                PersonPickerView { contact in
                    addPerson(from: contact)
                    showingPicker = false
                }
            }
            #endif
            #if os(macOS)
            .sheet(isPresented: $showingManualEntry) {
                PersonManualEntrySheet { name in
                    addPersonManually(name: name)
                }
            }
            #endif
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .task { contactsStore.refreshAuth() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("No People Yet").font(.title2.weight(.semibold))
            Text("Add someone you want to keep in touch with.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func addTapped() {
        #if os(iOS)
        Task {
            if contactsStore.authState != .authorized {
                await contactsStore.requestAccess()
            }
            if contactsStore.authState == .authorized {
                showingPicker = true
            }
        }
        #else
        showingManualEntry = true
        #endif
    }

    private func addPerson(from contact: CNContact) {
        let formatter = CNContactFormatter()
        formatter.style = .fullName
        let display = formatter.string(from: contact)
            ?? "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let person = TrackedPerson(
            contactIdentifier: contact.identifier,
            displayName: display.isEmpty ? "Unnamed" : display,
            photoData: contact.imageDataAvailable ? contact.imageData : nil
        )
        modelContext.insert(person)
    }

    private func addPersonManually(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(TrackedPerson(displayName: trimmed))
    }

    private func deletePeople(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(people[index])
        }
    }
}

struct PersonRow: View {
    let person: TrackedPerson

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let data = person.photoData, let img = platformImage(from: data) {
                    img.resizable().scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(person.displayName).font(.body)
                if let last = person.lastInteractionDate {
                    Text(daysSinceLabel(for: last))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No interactions yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func daysSinceLabel(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) days ago"
    }
}

#if canImport(UIKit)
import UIKit
func platformImage(from data: Data) -> Image? {
    UIImage(data: data).map { Image(uiImage: $0) }
}
#elseif canImport(AppKit)
import AppKit
func platformImage(from data: Data) -> Image? {
    NSImage(data: data).map { Image(nsImage: $0) }
}
#endif
