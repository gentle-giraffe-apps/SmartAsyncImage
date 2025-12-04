//  Jonathan Ritchey

import Foundation

public struct SmartAsyncImageEncoder: Sendable {
    public init() {
    }
    
    func encode(_ key: URL) -> String {
        key.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "unknown"
    }
    
    func decode(_ string: String) -> URL? {
        guard let decoded = string.removingPercentEncoding else { return nil }
        return URL(string: decoded)
    }
}
