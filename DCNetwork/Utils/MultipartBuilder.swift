//
//  DCNetwork
//

import Foundation
import DCUtils

extension Network {
    public class Multipart {
        public struct Item {
            
            let key         : String
            let value       : Data
            let mimeType    : String?
            let fileName    : String?
            
            public init(key: String, value: Data, mimeType: String? = nil, fileName: String? = nil) {
                self.key = key
                self.value = value
                self.mimeType = mimeType
                self.fileName = fileName
            }
            
        }
    }
}

extension Network.Multipart {
    public class Builder {
        
        public let boundary = "Boundary_" + NSUUID().uuidString
        private(set) var items = [Item]()
        
        public init() {
        }
        
        public init(values: [String:Any]) {
            for (key,value) in values {
                items << Item(key: key, value: "\(value)".data(using: .utf8)!)
            }
        }
        
        public init(items: [Item]) {
            self.items = items
        }
        
        public func add(item: Item) {
            items << item
        }
        
        public func buildData() -> Data {
            let data = NSMutableData()
            let prefix = "--\(boundary)\r\n".data(using: String.Encoding.utf8)!
            for item in items {
                data.append(prefix)
                if let fileName = item.fileName, let mimeType = item.mimeType {
                    data.append("Content-Disposition: form-data; name=\"\(item.key)\"; filename=\"\(fileName)\"\r\n".data(using: String.Encoding.utf8)!)
                    data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                } else {
                    data.append("Content-Disposition: form-data; name=\"\(item.key)\";\"\r\n".data(using: String.Encoding.utf8)!)
                }
                data.append(item.value)
                data.append("\r\n".data(using: .utf8)!)
            }
            data.append("--\(boundary)--".data(using: .utf8)!)
    //        _ = try? data.write(toFile: "/Users/igor/1.txt", options: .atomic)
            
            return data as Data
        }
        
    }
}
