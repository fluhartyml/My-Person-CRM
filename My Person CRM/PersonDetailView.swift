import SwiftUI
import SwiftData
import Contacts
import EventKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PersonDetailView: View {
    @Bindable var person: TrackedPerson
    @State private var contactsStore = ContactsStore()
    @State private var calendarStore = CalendarStore()
    @State private var showingAddInteraction = false
    @Environment(\.modelContext) private var modelContext

    private var contact: CNContact? {
        guard !person.contactIdentifier.isEmpty else { return nil }
        return contactsStore.contact(forIdentifier: person.contactIdentifier)
    }

    private var sortedInteractions: [Interaction] {
        (person.interactions ?? []).sorted(by: { $0.date > $1.date })
    }

    private var matchingEvents: [EKEvent] {
        guard calendarStore.authState == .authorized else { return [] }
        return calendarStore.upcomingEvents(matching: person.displayName)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                quickActions
                if let c = contact {
                    contactDetails(c)
                }
                if !matchingEvents.isEmpty {
                    upcomingEventsSection
                }
                interactionLogSection
            }
            .padding()
        }
        .navigationTitle(person.displayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddInteraction = true } label: {
                    Label("Log Interaction", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddInteraction) {
            AddInteractionSheet(person: person)
        }
        .task {
            contactsStore.refreshAuth()
            calendarStore.refreshAuth()
            if calendarStore.authState != .authorized {
                await calendarStore.requestAccess()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Group {
                if let data = person.photoData, let img = platformImage(from: data) {
                    img.resizable().scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())

            Text(person.displayName).font(.title.bold())

            if let last = person.lastInteractionDate {
                Text("Last interaction \(last, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 16) {
            quickActionButton(title: "Call", icon: "phone.fill", action: callTapped, enabled: contact?.phoneNumbers.first != nil)
            quickActionButton(title: "Message", icon: "message.fill", action: messageTapped, enabled: contact?.phoneNumbers.first != nil)
            quickActionButton(title: "Email", icon: "envelope.fill", action: emailTapped, enabled: contact?.emailAddresses.first != nil)
        }
    }

    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void, enabled: Bool) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
    }

    private func callTapped() {
        guard let phone = contact?.phoneNumbers.first?.value.stringValue else { return }
        openURL("tel://\(phone.filter { $0.isNumber || $0 == "+" })")
    }

    private func messageTapped() {
        guard let phone = contact?.phoneNumbers.first?.value.stringValue else { return }
        openURL("sms:\(phone.filter { $0.isNumber || $0 == "+" })")
    }

    private func emailTapped() {
        guard let email = contact?.emailAddresses.first?.value as String? else { return }
        openURL("mailto:\(email)")
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    private func contactDetails(_ contact: CNContact) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contact Info").font(.headline)
            ForEach(contact.phoneNumbers, id: \.identifier) { phone in
                HStack {
                    Image(systemName: "phone").foregroundStyle(.tint)
                    Text(phone.value.stringValue)
                    Spacer()
                    if let label = phone.label {
                        Text(CNLabeledValue<NSString>.localizedString(forLabel: label))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            ForEach(contact.emailAddresses, id: \.identifier) { email in
                HStack {
                    Image(systemName: "envelope").foregroundStyle(.tint)
                    Text(email.value as String)
                    Spacer()
                    if let label = email.label {
                        Text(CNLabeledValue<NSString>.localizedString(forLabel: label))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            if let bday = contact.birthday, let date = Calendar.current.date(from: bday) {
                HStack {
                    Image(systemName: "birthday.cake").foregroundStyle(.tint)
                    Text(date, style: .date)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Events").font(.headline)
            ForEach(matchingEvents, id: \.eventIdentifier) { event in
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title ?? "Untitled").font(.body)
                    Text(event.startDate, style: .date).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var interactionLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Interaction Log").font(.headline)
            if sortedInteractions.isEmpty {
                Text("No interactions logged yet.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            } else {
                ForEach(sortedInteractions) { interaction in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: interaction.type.icon)
                            .foregroundStyle(.tint)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(interaction.type.label).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(interaction.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !interaction.note.isEmpty {
                                Text(interaction.note).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    if interaction.id != sortedInteractions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
