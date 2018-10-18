//
//  DCNetwork
//

import SystemConfiguration
import Foundation
import DCUtils

public enum ReachabilityError: Error {
    case FailedToCreateWithAddress(sockaddr_in)
    case FailedToCreateWithHostname(String)
    case UnableToSetCallback
    case UnableToSetDispatchQueue
}

func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    
    guard let info = info else { return }
    
    let reachability = Unmanaged<Network.Reachability>.fromOpaque(info).takeUnretainedValue()
    
    DispatchQueue.main.async {
        reachability.reachabilityChanged()
    }
}

extension Notification.Name {
    public static let reachabilityDidChange = Notification.Name("Notification.Name_reachabilityDidChange")
}

public extension Network {
    public class Reachability {
        
        public typealias NetworkReachable = (Reachability) -> ()
        public typealias NetworkUnreachable = (Reachability) -> ()
        
        public enum Status: CustomStringConvertible {
            
            case notReachable
            case viaWiFi
            case viaWWAN
            
            public var description: String {
                switch self {
                case .viaWWAN       : return "Cellular"
                case .viaWiFi       : return "WiFi"
                case .notReachable  : return "No Connection"
                }
            }
        }
        
        static var internetReachability: Reachability?
        
        public static var internet: Reachability {
            if let item = internetReachability {return item}
            let item = Reachability()
            try? item.startNotifier()
            internetReachability = item
            return item
        }
        
        public var whenReachable: NetworkReachable?
        public var whenUnreachable: NetworkUnreachable?
        public var reachableOnWWAN: Bool
        
        public var status: Status {
            guard isReachable else {return .notReachable}
            if isReachableViaWiFi {return .viaWiFi}
            if isRunningOnDevice {return .viaWWAN}
            return .notReachable
        }
        
        fileprivate var previousFlags: SCNetworkReachabilityFlags?
        
        fileprivate var isRunningOnDevice: Bool = {
            #if targetEnvironment(simulator)
                return false
            #else
                return true
            #endif
        }()
        
        fileprivate var notifierRunning = false
        fileprivate var reachabilityRef: SCNetworkReachability?
        
        fileprivate let queue = DispatchQueue(label: "com.dcfoundation.reachability")
        
        public init?(hostname: String) {
            
            guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { return nil }
            reachableOnWWAN = true
            self.reachabilityRef = ref
        }
        
        init() {
            var zeroAddress = sockaddr()
            zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
            zeroAddress.sa_family = sa_family_t(AF_INET)
            
            if let ref: SCNetworkReachability = withUnsafePointer(to: &zeroAddress, { SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)) }) {
                self.reachabilityRef = ref
            } else {
                self.reachabilityRef = nil
            }
            reachableOnWWAN = true
        }
        
        deinit {
            stopNotifier()
            reachabilityRef = nil
            whenReachable = nil
            whenUnreachable = nil
        }
        
        func startNotifier() throws {
            guard let reachabilityRef = reachabilityRef, !notifierRunning else { return }
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
            context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
            if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
                stopNotifier()
                throw ReachabilityError.UnableToSetCallback
            }
            
            if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, queue) {
                stopNotifier()
                throw ReachabilityError.UnableToSetDispatchQueue
            }
            queue.async { self.reachabilityChanged() }
            notifierRunning = true
        }
        
        func stopNotifier() {
            defer { notifierRunning = false }
            guard let reachabilityRef = reachabilityRef else { return }
            SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
            SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
        }
        
        var isReachable: Bool {
            guard
                isReachableFlagSet,
                !isConnectionRequiredAndTransientFlagSet,
                !(isRunningOnDevice && isOnWWANFlagSet && !reachableOnWWAN)
            else { return false }
            return true
        }
        
        var isReachableViaWWAN: Bool { return isRunningOnDevice && isReachableFlagSet && isOnWWANFlagSet }
        
        var isReachableViaWiFi: Bool {
            guard isReachableFlagSet, isRunningOnDevice else { return false }
            return !isOnWWANFlagSet
        }
    }
}

fileprivate extension Network.Reachability {
    
    func reachabilityChanged() {
        let flags = reachabilityFlags
        guard previousFlags != flags else { return }
        let block = isReachable ? whenReachable : whenUnreachable
        block?(self)
        Notification.post(name: .reachabilityDidChange, object: self)
        previousFlags = flags
    }
    
    var isOnWWANFlagSet: Bool {
        #if os(iOS)
            return reachabilityFlags.contains(.isWWAN)
        #else
            return false
        #endif
    }
    var isReachableFlagSet                      : Bool { return reachabilityFlags.contains(.reachable) }
    var isConnectionRequiredFlagSet             : Bool { return reachabilityFlags.contains(.connectionRequired) }
    var isInterventionRequiredFlagSet           : Bool { return reachabilityFlags.contains(.interventionRequired) }
    var isConnectionOnTrafficFlagSet            : Bool { return reachabilityFlags.contains(.connectionOnTraffic) }
    var isConnectionOnDemandFlagSet             : Bool { return reachabilityFlags.contains(.connectionOnDemand) }
    var isConnectionOnTrafficOrDemandFlagSet    : Bool { return !reachabilityFlags.intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty }
    var isTransientConnectionFlagSet            : Bool { return reachabilityFlags.contains(.transientConnection) }
    var isLocalAddressFlagSet                   : Bool { return reachabilityFlags.contains(.isLocalAddress) }
    var isDirectFlagSet                         : Bool { return reachabilityFlags.contains(.isDirect) }
    var isConnectionRequiredAndTransientFlagSet : Bool { return reachabilityFlags.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection] }
    
    var reachabilityFlags: SCNetworkReachabilityFlags {
        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }
        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(to: &flags) { SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0)) }
        return gotFlags ? flags : SCNetworkReachabilityFlags()
    }
}
