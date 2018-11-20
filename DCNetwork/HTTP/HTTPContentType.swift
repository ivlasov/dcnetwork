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
    public static let formURLEncoded       = HTTP.ContentType("application/x-www-form-urlencoded")
    public static let multipartFormData    = HTTP.ContentType("multipart/form-data")
    public static let json                 = HTTP.ContentType("application/json")
}
