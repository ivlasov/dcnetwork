//
//  DCNetwork
//

import Foundation
import DCUtils
import DCLog

extension Network.HTTP {
    open class Request {
        
        public enum ContentType: String {
            case formURLEncoded     = "application/x-www-form-urlencoded"
            case multipartFormData  = "multipart/form-data"
            case json               = "application/json"
            case custom             = "custom"
        }
        
        public enum Method: String {
            case post   = "POST"
            case get    = "GET"
            case put    = "PUT"
            case delete = "DELETE"
        }
        
        public let id = NSUUID().uuidString
        
        public let url                  : URL
        public var headers              : [String:String]
        public var method               : Method
        public var body                 : Any?
        public var query                : [String:Any]?
        public var contentType          = ContentType.custom
        public var shouldHandleCookies  = false
        public var isLoggingEnabled     = true
        
        fileprivate var queryString: String {
            guard let query = query, query.count > 0 else { return "" }
            var items = [String]()
            for (key,value) in query {
                let eKey = "\(value)".URLEncodedString()
                items << "\(key.URLEncodedString())=\(eKey)"
            }
            return "?" + items.joinedBy(separator: "&")
        }
        
        public var urlRequest: URLRequest {
            var url = self.url
            if queryString.length > 0 {
                url = URL(string: self.url.absoluteString + queryString)!
            }
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.httpShouldHandleCookies = shouldHandleCookies
            if shouldHandleCookies, let cookies = HTTPCookieStorage.shared.cookies(for: url) {
                for (key,value) in HTTPCookie.requestHeaderFields(with: cookies) {
                    request.addValue(value, forHTTPHeaderField: key)
                }
            }
            for (key,value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            if contentType != .custom {
                request.addValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
            }
            if let body = body as? Data {
                request.httpBody = body
            } else if let values = body as? [String:Any] {
                switch contentType {
                case .json:
                    request.httpBody = try? JSONSerialization.data(withJSONObject: values, options: .prettyPrinted)
                case .multipartFormData:
                    let multipart = Network.Multipart.Builder(values: values)
                    request.addValue(contentType.rawValue + ";boundary=\(multipart.boundary)", forHTTPHeaderField: "Content-Type")
                    request.httpBody = multipart.buildData()
                    break
                default: break
                }
            } else if let items = body as? [Network.Multipart.Item] {
                let multipart = Network.Multipart.Builder(items: items)
                request.addValue(contentType.rawValue + ";boundary=\(multipart.boundary)", forHTTPHeaderField: "Content-Type")
                request.httpBody = multipart.buildData()
            }
            return request
        }
        
        public init(url: URL, method: Method = .get, isLoggingEnabled: Bool = true) {
            self.isLoggingEnabled = isLoggingEnabled
            self.url = url
            self.method = method
            headers = [:]
        }
        
        public init(request: Request) {
            url = request.url
            method = request.method
            query = request.query
            body = request.body
            headers = request.headers
        }
        
        public func logPrint() {
            guard isLoggingEnabled else { return }
            
//            Log.current().execute(category: .network, priority: <#T##Int#>, parameters: <#T##[String : Any]?#>)
    //        Log.current().push(category: .network, parameters: ["text":"Request".fitIn(length: 40, symbol: "-")])
            print("----------------Request----------------")
            print("\(method.rawValue) \(url.absoluteString)?\(queryString)")
            print(headers)
            if let body = body as? Data {
                if let string = String(data: body, encoding: .utf8) {
                    print(string)
                }
            } else if let body = body as? [String:Any] {
                print(body)
            }
            print("---------------------------------------")
        }
        
    }
}

extension Network.HTTP.Request: LogDescription {
    public func logDescription() -> String {
        return ""
    }
}
