import Foundation

enum ZoomdleLegal {
    static var privacyURL: URL? { url(for: "NSPrivacyPolicyURL") }
    static var supportURL: URL? { url(for: "SupportURL") }
    static var termsURL: URL? { url(for: "TermsURL") }

    private static func url(for key: String) -> URL? {
        guard let string = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        return URL(string: string)
    }
}
