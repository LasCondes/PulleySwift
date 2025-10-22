import Foundation
import PulleyCore

/// ANSI standard for shaft design
/// Converted from C++ cANSI in cANSI.cpp
public final class ANSIStandard: Criterium {
    public let standardName = "ANSI"

    public init() {}

    /// Calculate safety factor for shaft under bending and torsion
    /// - Parameters:
    ///   - isLiveShaft: True for live shaft (rotating), false for dead shaft
    ///   - diameter: Shaft diameter in mm
    ///   - moment: Bending moment in N·mm
    ///   - torque: Torsional moment in N·mm
    ///   - material: Material properties
    ///   - fatigueStressConcentrationFactor: Kf factor (typically from geometric discontinuities)
    /// - Returns: Safety factor (dimensionless)
    public func calculateSafetyFactor(
        isLiveShaft: Bool,
        diameter: Double,
        moment: Double,
        torque: Double,
        material: Material,
        fatigueStressConcentrationFactor: Double = 1.0
    ) -> Double {
        let D = diameter
        let M = moment
        let T = torque
        let Sy = material.yieldStrength
        let Kf = fatigueStressConcentrationFactor

        // Marin factors for fatigue strength modification
        let Ka = 0.8  // Surface factor for machined shaft
        let Kb = pow(D / 25.4, -0.19)  // Size factor (25.4mm = 1 inch)
        let Kc = 0.897  // Reliability factor (50% reliability)
        let Kd = 1.0  // Temperature factor for -70°F to 400°F
        let Ke = 1.0  // Duty cycle factor
        let Kg = 1.0  // Miscellaneous factor

        // Base fatigue strength
        var Sfprime = material.enduranceLimit
        if !isLiveShaft {
            // Dead shaft uses yield strength instead of endurance limit
            Sfprime = material.yieldStrength
        }

        // Modified fatigue strength
        let Sf = Ka * Kb * Kc * Kd * Ke * Kf * Kg * Sfprime

        // Calculate von Mises equivalent stress criterion
        // FS = (π*D³/32) / sqrt((M/Sf)² + (3/4)*(T/Sy)²)
        let div1 = sqrt(pow(M / Sf, 2) + 0.75 * pow(T / Sy, 2))

        // Check for divide by zero
        if abs(div1) < 1e-10 {
            return Double.greatestFiniteMagnitude  // Infinite safety factor
        }

        let FS = pow(D, 3) * Double.pi / 32.0 / div1

        return FS
    }

    /// Calculate minimum required diameter for given loading
    /// - Parameters:
    ///   - isLiveShaft: True for live shaft (rotating), false for dead shaft
    ///   - currentDiameter: Current diameter in mm (used for size factor calculation)
    ///   - moment: Bending moment in N·mm
    ///   - torque: Torsional moment in N·mm
    ///   - material: Material properties
    ///   - fatigueStressConcentrationFactor: Kf factor
    ///   - requiredSafetyFactor: Minimum required safety factor
    /// - Returns: Minimum diameter in mm
    public func minimumDiameter(
        isLiveShaft: Bool,
        currentDiameter: Double,
        moment: Double,
        torque: Double,
        material: Material,
        fatigueStressConcentrationFactor: Double = 1.0,
        requiredSafetyFactor: Double = 1.0
    ) -> Double {
        let M = moment
        let T = torque
        let Sy = material.yieldStrength
        let Kf = fatigueStressConcentrationFactor

        // Marin factors (using current diameter for size factor)
        let Ka = 0.8
        let Kb = pow(currentDiameter / 25.4, -0.19)
        let Kc = 0.897
        let Kd = 1.0
        let Ke = 1.0
        let Kg = 1.0

        var Sfprime = material.enduranceLimit
        if !isLiveShaft {
            Sfprime = material.yieldStrength
        }

        let Sf = Ka * Kb * Kc * Kd * Ke * Kf * Kg * Sfprime

        // Solve for diameter: D³ = (32*FS/π) * sqrt((M/Sf)² + (3/4)*(T/Sy)²)
        let term = sqrt(pow(M / Sf, 2) + 0.75 * pow(T / Sy, 2))
        let Dcubed = (32.0 * requiredSafetyFactor / Double.pi) * term
        let Dmin = pow(Dcubed, 1.0/3.0)

        return Dmin
    }

    // MARK: - Criterium Protocol

    public func calculateSafetyFactor(stress: Double, material: Material) -> Double {
        // Simplified interface - assumes pure bending
        // For full analysis, use the detailed method above
        return material.yieldStrength / stress
    }
}
