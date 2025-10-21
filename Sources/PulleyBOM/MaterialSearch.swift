import Foundation
import PulleyCore

/// Material search result
/// Converted from C++ cSearch in cBill.h
public struct MaterialSearchResult {
    public let success: Bool
    public let material: Material?
    public let searchDescription: String
    public let targetDescription: String?

    public init(
        success: Bool,
        material: Material? = nil,
        searchDescription: String,
        targetDescription: String? = nil
    ) {
        self.success = success
        self.material = material
        self.searchDescription = searchDescription
        self.targetDescription = targetDescription
    }
}

/// Material database interface
public protocol MaterialDatabase {
    /// Find material by item number
    func findMaterial(itemNumber: String) -> MaterialSearchResult

    /// Find suitable plate material with minimum thickness
    func findPlate(materialNumber: String, minimumThickness: Double) -> (thickness: Double, cost: Double)?
}
