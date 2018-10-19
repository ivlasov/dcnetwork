//
//  DCNetwork
//

import Foundation

extension HTTP {
    open class Response {

        fileprivate let response    : HTTPURLResponse?
        
        public let responseError   : Error?
        public let data            : Data?
        
        public var url             : URL? {
            return response?.url
        }
        
        public var statusCode      : Int {
            return response?.statusCode ?? 0
        }
        
        public var headers         : [String:String] {
            return response?.allHeaderFields as? [String:String] ?? [:]
        }
        
        public var cookies          : [HTTPCookie]? {
            if let url = url {
                return HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
            }
            return nil
        }
        
        public let isLoggingEnabled: Bool
        
        required public init(response: HTTPURLResponse?, data: Data?, error: Error?, isLoggingEnabled: Bool = true) {
            self.isLoggingEnabled = isLoggingEnabled
            self.response = response
            self.data = data
            self.responseError = error
        }
        
        public func logPrint() {
            guard isLoggingEnabled else { return }
            print("----------------Response---------------")
            print("\(url?.absoluteString ?? "")")
            print(headers)
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            }
            print("---------------------------------------")
        }
        
    }
}
