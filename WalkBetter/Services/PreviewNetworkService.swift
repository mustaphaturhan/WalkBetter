import Foundation

class PreviewNetworkService: NetworkConnectivityService {
    override var isConnected: Bool {
        get { _isConnected }
        set { _isConnected = newValue }
    }
    private var _isConnected: Bool

    init(isConnected: Bool) {
        self._isConnected = isConnected
        super.init()
    }

    override func checkConnectivity() -> Bool {
        isConnected
    }
}

extension NetworkConnectivityService {
    static func preview(isConnected: Bool) -> NetworkConnectivityService {
        PreviewNetworkService(isConnected: isConnected)
    }
}
