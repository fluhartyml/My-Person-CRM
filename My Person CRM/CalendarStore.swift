import Foundation
import EventKit
import Observation

@MainActor
@Observable
final class CalendarStore {
    enum AuthState { case unknown, authorized, denied, notDetermined }

    var authState: AuthState = .unknown
    var lastError: String?

    private let store = EKEventStore()

    func refreshAuth() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .authorized, .writeOnly: authState = .authorized
        case .denied, .restricted: authState = .denied
        case .notDetermined: authState = .notDetermined
        @unknown default: authState = .unknown
        }
    }

    func requestAccess() async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authState = granted ? .authorized : .denied
        } catch {
            lastError = error.localizedDescription
            authState = .denied
        }
    }

    func upcomingEvents(matching searchTerm: String, limit: Int = 5) -> [EKEvent] {
        guard !searchTerm.isEmpty else { return [] }
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
        let predicate = store.predicateForEvents(withStart: now, end: oneYearFromNow, calendars: nil)
        let lc = searchTerm.lowercased()
        return store.events(matching: predicate)
            .filter { event in
                if event.title?.lowercased().contains(lc) == true { return true }
                if event.notes?.lowercased().contains(lc) == true { return true }
                if event.attendees?.contains(where: { $0.name?.lowercased().contains(lc) == true }) == true { return true }
                return false
            }
            .prefix(limit)
            .map { $0 }
    }
}
