import Foundation

struct ErrorHandlingService {
    static func handleError(
        _ error: Error,
        operation: String,
        onError: (String) -> Void
    ) {
        let logMessage: String
        let errorMessage: String

        if let locationError = error as? LocationListError {
            errorMessage = locationError.errorDescription ?? "An unknown error occurred"
            logMessage = "❌ \(operation): \(locationError)"
        } else {
            errorMessage = error.localizedDescription
            logMessage = "❌ \(operation): \(error.localizedDescription)"
        }

        print(logMessage)
        onError(errorMessage)
    }
}
