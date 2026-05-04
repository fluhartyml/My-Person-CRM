import Foundation
import SwiftData

@Model
final class TrackedPerson {
    var contactIdentifier: String = ""
    var displayName: String = ""
    var photoData: Data? = nil
    var addedAt: Date = Date()
    var personalNotes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Interaction.person)
    var interactions: [Interaction]? = nil

    init(contactIdentifier: String = "",
         displayName: String = "",
         photoData: Data? = nil,
         addedAt: Date = Date(),
         personalNotes: String = "") {
        self.contactIdentifier = contactIdentifier
        self.displayName = displayName
        self.photoData = photoData
        self.addedAt = addedAt
        self.personalNotes = personalNotes
    }

    var lastInteractionDate: Date? {
        interactions?.sorted(by: { $0.date > $1.date }).first?.date
    }
}

@Model
final class Interaction {
    var typeRaw: String = InteractionType.note.rawValue
    var date: Date = Date()
    var note: String = ""

    var person: TrackedPerson? = nil

    init(type: InteractionType = .note, date: Date = Date(), note: String = "") {
        self.typeRaw = type.rawValue
        self.date = date
        self.note = note
    }

    var type: InteractionType {
        get { InteractionType(rawValue: typeRaw) ?? .note }
        set { typeRaw = newValue.rawValue }
    }
}

enum InteractionType: String, CaseIterable, Identifiable, Codable {
    case call
    case message
    case email
    case visit
    case note

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .call: return "phone.fill"
        case .message: return "message.fill"
        case .email: return "envelope.fill"
        case .visit: return "person.2.fill"
        case .note: return "note.text"
        }
    }

    var label: String {
        switch self {
        case .call: return "Call"
        case .message: return "Message"
        case .email: return "Email"
        case .visit: return "Visit"
        case .note: return "Note"
        }
    }
}
