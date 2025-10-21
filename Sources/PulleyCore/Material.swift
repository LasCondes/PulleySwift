import Foundation

/// Material properties for pulley components
/// Converted from C++ sMaterial struct in sPulleyInput.h
public struct Material: Codable, Equatable {
    /// Material identifier from materials database
    public let itemNumber: String

    /// Young's modulus (modulus of elasticity) in MPa
    public let youngsModulus: Double

    /// Poisson's ratio (dimensionless)
    public let poissonsRatio: Double

    /// Yield strength in MPa
    public let yieldStrength: Double

    /// Endurance limit (fatigue strength) in MPa
    public let enduranceLimit: Double

    /// Ultimate tensile strength in MPa
    public let ultimateStrength: Double

    /// Density in kg/m³
    public let density: Double

    /// Base stress value in MPa (for DIN15018 calculations)
    public let baseStress: Double

    public init(
        itemNumber: String,
        youngsModulus: Double,
        poissonsRatio: Double,
        yieldStrength: Double,
        enduranceLimit: Double,
        ultimateStrength: Double,
        density: Double,
        baseStress: Double
    ) {
        self.itemNumber = itemNumber
        self.youngsModulus = youngsModulus
        self.poissonsRatio = poissonsRatio
        self.yieldStrength = yieldStrength
        self.enduranceLimit = enduranceLimit
        self.ultimateStrength = ultimateStrength
        self.density = density
        self.baseStress = baseStress
    }

    enum CodingKeys: String, CodingKey {
        case itemNumber
        case youngsModulus = "E"
        case poissonsRatio = "nu"
        case yieldStrength
        case enduranceLimit
        case ultimateStrength
        case density
        case baseStress = "sB0"
    }
}
