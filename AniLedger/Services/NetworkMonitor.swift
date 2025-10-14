import Foundation
import Network
import Combine

/// Monitors network connectivity status using NWPathMonitor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.aniledger.networkmonitor")
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                // Notify when connection is restored
                if path.status == .satisfied {
                    NotificationCenter.default.post(name: .networkConnectionRestored, object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
}

extension Notification.Name {
    static let networkConnectionRestored = Notification.Name("networkConnectionRestored")
}
