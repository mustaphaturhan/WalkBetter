import Foundation

enum NetworkError: LocalizedError {
    case noInternetConnection
    case routeOptimizationFailed
    case locationSearchFailed

    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection available. Please check your connection and try again."
        case .routeOptimizationFailed:
            return "Unable to optimize route. Please check your internet connection and try again."
        case .locationSearchFailed:
            return "Unable to search locations. Please check your internet connection and try again."
        }
    }
}
