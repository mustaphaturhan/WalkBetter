import Foundation
import SwiftData

enum ListManagementService {
    static func deleteList(_ list: LocationList, context: ModelContext) {
        context.delete(list)
        print("✅ Successfully deleted list: \(list.name)")
    }

    static func createSampleLists(in context: ModelContext) {
        // Create all sample lists
        let brusselsList = PreviewHelperService.createBrusselsList(in: context)
        _ = PreviewHelperService.createParisList(in: context)
        let londonList = PreviewHelperService.createLondonList(in: context)
        _ = PreviewHelperService.createRomeList(in: context)
        _ = PreviewHelperService.createAmsterdamList(in: context)
        let istanbulList = PreviewHelperService.createIstanbulList(in: context)

        // Optimize some lists to show different states
        brusselsList.isOptimized = true
        londonList.isOptimized = true
        istanbulList.isOptimized = true

        // Empty list for testing
        let emptyList = LocationList(name: "Weekend Walk")
        context.insert(emptyList)

        print("✅ Successfully created sample lists")
    }
}
