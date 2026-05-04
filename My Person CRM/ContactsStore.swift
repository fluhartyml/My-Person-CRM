import Foundation
import Contacts
import Observation

@MainActor
@Observable
final class ContactsStore {
    enum AuthState { case unknown, authorized, denied, notDetermined }

    var authState: AuthState = .unknown
    var lastError: String?

    private let store = CNContactStore()

    func refreshAuth() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: authState = .authorized
        case .denied, .restricted: authState = .denied
        case .notDetermined: authState = .notDetermined
        @unknown default: authState = .unknown
        }
    }

    func requestAccess() async {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            authState = granted ? .authorized : .denied
        } catch {
            lastError = error.localizedDescription
            authState = .denied
        }
    }

    func contact(forIdentifier identifier: String) -> CNContact? {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ]
        return try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
    }
}
