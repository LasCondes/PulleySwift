import Foundation

/// Locking assembly configuration for shaft connection
/// Converted from C++ sLockingAssemblyInput struct in sPulleyInput.h
public struct LockingAssembly: Codable, Equatable {
    /// Assembly item identifier
    public let item: String

    /// Inner width in mm
    public let innerWidth: Double

    /// Outer width in mm
    public let outerWidth: Double

    /// Pressure on hub in MPa
    public let pressureOnHub: Double

    /// Inner diameter in mm
    public let innerDiameter: Double

    /// Outer diameter in mm
    public let outerDiameter: Double

    /// Include bending moment in hub calculation
    public let includeBendingMomentInHub: Bool

    /// Torque capacity derate setting
    public let derateTorque: String

    /// Torque capacity in Nm
    public let torqueCapacity: Double

    /// Manufacturer name
    public let manufacturer: String

    /// Model designation
    public let model: String

    public init(
        item: String,
        innerWidth: Double,
        outerWidth: Double,
        pressureOnHub: Double,
        innerDiameter: Double,
        outerDiameter: Double,
        includeBendingMomentInHub: Bool,
        derateTorque: String,
        torqueCapacity: Double,
        manufacturer: String,
        model: String
    ) {
        self.item = item
        self.innerWidth = innerWidth
        self.outerWidth = outerWidth
        self.pressureOnHub = pressureOnHub
        self.innerDiameter = innerDiameter
        self.outerDiameter = outerDiameter
        self.includeBendingMomentInHub = includeBendingMomentInHub
        self.derateTorque = derateTorque
        self.torqueCapacity = torqueCapacity
        self.manufacturer = manufacturer
        self.model = model
    }
}
