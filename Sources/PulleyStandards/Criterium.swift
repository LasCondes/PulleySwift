import Foundation
import PulleyCore

/// Base protocol for engineering design criteria
/// Converted from C++ cCriterium base class
public protocol Criterium {
    /// Name of the engineering standard
    var standardName: String { get }

    /// Calculate safety factor for given stress conditions
    /// - Parameters:
    ///   - stress: Applied stress in MPa
    ///   - material: Material properties
    /// - Returns: Safety factor (dimensionless)
    func calculateSafetyFactor(stress: Double, material: Material) -> Double

    /// Check if design passes criterion
    /// - Parameters:
    ///   - stress: Applied stress in MPa
    ///   - material: Material properties
    ///   - minimumSafetyFactor: Required minimum safety factor
    /// - Returns: True if design passes
    func passes(stress: Double, material: Material, minimumSafetyFactor: Double) -> Bool
}

extension Criterium {
    public func passes(stress: Double, material: Material, minimumSafetyFactor: Double = 1.0) -> Bool {
        let safetyFactor = calculateSafetyFactor(stress: stress, material: material)
        return safetyFactor >= minimumSafetyFactor
    }
}
