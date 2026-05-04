import SwiftUI
import SwiftData

struct AddInteractionSheet: View {
    @Bindable var person: TrackedPerson
    @State private var type: InteractionType = .call
    @State private var date: Date = Date()
    @State private var note: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(InteractionType.allCases) { t in
                            Label(t.label, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("When") {
                    DatePicker("Date", selection: $date)
                }
                Section("Note") {
                    TextField("What happened?", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Log Interaction")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let interaction = Interaction(type: type, date: date, note: note)
        interaction.person = person
        modelContext.insert(interaction)
        if person.interactions == nil {
            person.interactions = [interaction]
        } else {
            person.interactions?.append(interaction)
        }
        dismiss()
    }
}
