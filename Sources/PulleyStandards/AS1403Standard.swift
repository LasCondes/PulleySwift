import Foundation
import PulleyCore

/// AS 1403 Australian standard for pulley shaft design
/// Converted from C++ cAS1403 in cAS1403.cpp
public final class AS1403Standard: Criterium {
    public let standardName = "AS 1403"

    public init() {}

    /// Calculate stepped shaft stress concentration factor K
    /// - Parameters:
    ///   - Z: Geometric parameter (related to fillet radius)
    ///   - Fu: Material ultimate tensile strength in MPa
    /// - Returns: Stress concentration factor K
    public static func steppedShaftFactorK(Z: Double, Fu: Double) -> Double {
        // 2D table of K(Fu, Z) from AS 1403
        let FuValues: [Double] = [350, 400, 500, 600, 700, 800, 900]
        let ZValues: [Double] = [0, 0.05, 0.1, 0.2, 0.3, 0.5]

        // K-table values (rows are Fu, columns are Z)
        let Ktable: [[Double]] = [
            [3.0, 2.1, 1.85, 1.60, 1.50, 1.40],  // Fu = 350
            [3.0, 2.2, 1.90, 1.65, 1.55, 1.45],  // Fu = 400
            [3.0, 2.3, 2.00, 1.75, 1.65, 1.50],  // Fu = 500
            [3.0, 2.4, 2.10, 1.85, 1.70, 1.55],  // Fu = 600
            [3.0, 2.5, 2.20, 1.90, 1.75, 1.60],  // Fu = 700
            [3.0, 2.6, 2.25, 1.95, 1.80, 1.65],  // Fu = 800
            [3.0, 2.7, 2.30, 2.00, 1.85, 1.70]   // Fu = 900
        ]

        // Interpolate in Fu dimension
        guard let (fuIndex, fuFraction) = interpolationFactor(lookup: Fu, values: FuValues, extrapolate: true) else {
            return 3.0  // Default maximum K
        }

        // Interpolate in Z dimension
        guard let (zIndex, zFraction) = interpolationFactor(lookup: Z, values: ZValues, extrapolate: true) else {
            return 3.0
        }

        // Bilinear interpolation
        let K00 = Ktable[fuIndex][zIndex]
        let K01 = Ktable[fuIndex][min(zIndex + 1, ZValues.count - 1)]
        let K10 = Ktable[min(fuIndex + 1, FuValues.count - 1)][zIndex]
        let K11 = Ktable[min(fuIndex + 1, FuValues.count - 1)][min(zIndex + 1, ZValues.count - 1)]

        let K0 = K00 + zFraction * (K01 - K00)
        let K1 = K10 + zFraction * (K11 - K10)
        let K = K0 + fuFraction * (K1 - K0)

        return K
    }

    /// Check if Fu is within valid range
    public static func isInside(Fu: Double) -> Bool {
        return Fu >= 350 && Fu <= 900
    }

    /// Calculate stepped shaft geometric factor Delta
    /// - Parameters:
    ///   - D: Larger diameter
    ///   - D1: Smaller diameter
    /// - Returns: Delta factor
    public static func steppedShaftFactorDelta(D: Double, D1: Double) -> Double {
        return (D - D1) / D
    }

    /// Calculate stress concentration factor for stepped shaft
    /// - Parameters:
    ///   - D: Larger diameter
    ///   - D1: Smaller diameter
    ///   - R: Fillet radius
    ///   - Fu: Ultimate tensile strength
    /// - Returns: Stress concentration factor
    public static func steppedShaftFactor(D: Double, D1: Double, R: Double, Fu: Double) -> Double {
        let delta = steppedShaftFactorDelta(D: D, D1: D1)
        let Z = 2.0 * R / D1
        return steppedShaftFactorK(Z: Z * delta, Fu: Fu)
    }

    /// Combine stress factors from nearby discontinuities
    /// - Parameters:
    ///   - distance: Distance to closest other stress point
    ///   - diameter: Shaft diameter
    ///   - K: Stress factor at this position
    ///   - Kcloseby: Stress factor at nearby location
    /// - Returns: Combined stress factor
    public static func combinedStress(distance: Double, diameter: Double, K: Double, Kcloseby: Double) -> Double {
        // If stress points are close (< 1 diameter apart), combine factors
        guard distance < diameter else {
            return K  // Too far apart, no interaction
        }

        let ratio = distance / diameter
        let weight = 1.0 - ratio  // Linear interpolation weight

        // Weighted combination of stress factors
        return K + weight * (Kcloseby - 1.0)
    }

    /// Calculate safety factor for shaft under combined loading
    /// - Parameters:
    ///   - hasTorqueReversal: True if torque reverses direction
    ///   - isLiveShaft: True for rotating shaft
    ///   - diameter: Shaft diameter in mm
    ///   - moment: Bending moment in N·mm
    ///   - torque: Torsional moment in N·mm
    ///   - material: Material properties
    ///   - stressConcentrationFactor: K factor from geometry
    /// - Returns: Safety factor
    public func calculateSafetyFactor(
        hasTorqueReversal: Bool,
        isLiveShaft: Bool,
        diameter: Double,
        moment: Double,
        torque: Double,
        material: Material,
        stressConcentrationFactor K: Double = 1.0
    ) -> Double {
        let D = diameter
        let M = moment
        let T = torque
        let Sy = material.yieldStrength
        let Su = material.ultimateStrength

        // Determine fatigue strength
        var Sf = material.enduranceLimit
        if !isLiveShaft {
            Sf = material.yieldStrength
        }

        // Apply stress concentration
        let Sf_effective = Sf / K

        // Equivalent stress calculation (von Mises-based)
        let sigmaBending = 32.0 * M / (Double.pi * pow(D, 3))
        let tauTorsion = 16.0 * T / (Double.pi * pow(D, 3))

        // For torque reversal, treat torsion as fully reversed
        let tauEffective = hasTorqueReversal ? tauTorsion : tauTorsion / 2.0

        // Combined stress criterion
        let sigmaEquiv = sqrt(pow(sigmaBending / Sf_effective, 2) + 3.0 * pow(tauEffective / Sy, 2))

        // Safety factor
        guard sigmaEquiv > 1e-10 else {
            return Double.greatestFiniteMagnitude
        }

        return 1.0 / sigmaEquiv
    }

    // MARK: - Criterium Protocol

    public func calculateSafetyFactor(stress: Double, material: Material) -> Double {
        // Simplified interface
        return material.yieldStrength / stress
    }

    // MARK: - Helper Methods

    /// Calculate interpolation factor for table lookup
    private static func interpolationFactor(
        lookup: Double,
        values: [Double],
        extrapolate: Bool = false
    ) -> (index: Int, fraction: Double)? {
        guard values.count >= 2 else { return nil }

        // Below table start
        if lookup <= values[0] {
            if !extrapolate { return nil }
            let f = (lookup - values[0]) / (values[1] - values[0])
            return (0, f)
        }

        // Above table end
        if lookup > values[values.count - 1] {
            if !extrapolate { return nil }
            let f = (lookup - values[values.count - 1]) / (values[values.count - 1] - values[values.count - 2])
            return (values.count - 2, f)
        }

        // Find index
        var si = -1
        for x in values {
            if x >= lookup { break }
            si += 1
        }

        // Interpolation fraction
        var f = 0.0
        if abs(values[si + 1] - values[si]) > 1e-10 {
            f = (lookup - values[si]) / (values[si + 1] - values[si])
        }

        return (si, f)
    }
}
