//
//  DCNetwork-
//

import Foundation

extension HTTP {
    public struct ContentType {
        public let rawValue: String
    }
}

extension HTTP.ContentType: Equatable {
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static func ==(lhs: HTTP.ContentType, rhs: HTTP.ContentType) -> Bool {
        return lhs.rawValue == lhs.rawValue
    }
}

extension HTTP.ContentType {
    static let formURLEncoded       = HTTP.ContentType("application/x-www-form-urlencoded")
    static let multipartFormData    = HTTP.ContentType("multipart/form-data")
    static let json                 = HTTP.ContentType("application/json")
}
