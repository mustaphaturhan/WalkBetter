import Foundation
import Network

@Observable
class NetworkConnectivityService {
    static let shared = NetworkConnectivityService()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected = false
    var connectionDescription: String {
        isConnected ? "Connected" : "No Internet Connection"
    }

    init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                print("🌐 Network status changed: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            }
        }
        monitor.start(queue: queue)
    }

    func checkConnectivity() -> Bool {
        isConnected
    }

    deinit {
        monitor.cancel()
    }
}
