import Foundation

enum LocationListError: LocalizedError {
    case optimizationFailed
    case saveFailed
    case modelContextMissing

    var errorDescription: String? {
        switch self {
        case .optimizationFailed:
            return "Failed to optimize route. Please try again."
        case .saveFailed:
            return "Failed to save changes. Please try again."
        case .modelContextMissing:
            return "Unable to save changes. Please try again."
        }
    }
}
