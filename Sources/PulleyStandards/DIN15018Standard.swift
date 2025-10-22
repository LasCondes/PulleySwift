import Foundation
import PulleyCore

/// DIN 15018 crane code for alternating stresses in welds
/// Used by German engineering firms for balance machines and pulleys
/// Converted from C++ cDIN15018 in cDIN15018.cpp
public final class DIN15018Standard: Criterium {
    public let standardName = "DIN 15018"

    public init() {}

    /// Calculate combined utilization factor BW for fatigue
    /// - Parameters:
    ///   - baseStress: Material base stress sB0 (typically 490 MPa)
    ///   - notchFactor: Knot factor KF for weld (0-4)
    ///   - radialStresses: Array of radial stress values over rotation
    ///   - tangentialStresses: Array of tangential stress values over rotation
    ///   - shearStresses: Array of shear stress values over rotation
    /// - Returns: Tuple with (BW, kappa values, max stresses, angle)
    public func calculateBW(
        baseStress sB0: Double,
        notchFactor KF: Int,
        radialStresses: [Double],
        tangentialStresses: [Double],
        shearStresses: [Double]
    ) -> (
        BW: Double,
        kappaR: Double,
        kappaT: Double,
        kappaTau: Double,
        maxRadial: Double,
        maxTangential: Double,
        maxShear: Double,
        maxAngle: Double
    ) {
        guard radialStresses.count == tangentialStresses.count,
              radialStresses.count == shearStresses.count,
              !radialStresses.isEmpty else {
            return (BW: 0, kappaR: 0, kappaT: 0, kappaTau: 0,
                    maxRadial: 0, maxTangential: 0, maxShear: 0, maxAngle: 0)
        }

        let count = radialStresses.count

        // Calculate kappa values (stress ratio)
        let kappaR = Self.calculateKappa(stresses: radialStresses)
        let kappaT = Self.calculateKappa(stresses: tangentialStresses)
        let kappaTau = Self.calculateKappa(stresses: shearStresses)

        // Find maximum combined stress utilization
        var BWmax = -Double.greatestFiniteMagnitude
        var jmax = 0

        for j in 0..<count {
            let sigmaR = radialStresses[j]
            let sigmaT = tangentialStresses[j]
            let tau = shearStresses[j]

            // Allowable shear stress (Table 18 and 19)
            let zulTauD = Self.sigZ(kappa: kappaTau, stress: abs(tau), notchFactor: KF, baseStress: sB0) / sqrt(2.0)

            // Combined utilization factor (von Mises-like criterion)
            var BW_j = pow(sigmaR / Self.sigZ(kappa: kappaR, stress: sigmaR, notchFactor: KF, baseStress: sB0), 2)
            BW_j += pow(sigmaT / Self.sigZ(kappa: kappaT, stress: sigmaT, notchFactor: KF, baseStress: sB0), 2)
            BW_j -= sigmaR * sigmaT / abs(
                Self.sigZ(kappa: kappaR, stress: sigmaR, notchFactor: KF, baseStress: sB0) *
                Self.sigZ(kappa: kappaT, stress: sigmaT, notchFactor: KF, baseStress: sB0)
            )
            BW_j += pow(tau / zulTauD, 2)

            if BW_j > BWmax {
                BWmax = BW_j
                jmax = j
            }
        }

        let maxAngle = Double(jmax) * 2.0 * Double.pi / Double(count)

        return (
            BW: BWmax,
            kappaR: kappaR,
            kappaT: kappaT,
            kappaTau: kappaTau,
            maxRadial: radialStresses[jmax],
            maxTangential: tangentialStresses[jmax],
            maxShear: shearStresses[jmax],
            maxAngle: maxAngle
        )
    }

    /// Calculate kappa (stress ratio) = σ_min / σ_max
    /// Kappa ranges from -1 (fully reversed) to +1 (pulsating)
    private static func calculateKappa(stresses: [Double]) -> Double {
        guard !stresses.isEmpty else { return 0 }

        let minStress = stresses.min()!
        let maxStress = stresses.max()!

        // Find numerically smaller and larger values
        var smaller = minStress
        var larger = maxStress

        if abs(smaller) > abs(larger) {
            smaller = maxStress
            larger = minStress
        }

        // Calculate kappa with proper sign
        guard larger != 0 else { return 0 }

        let magnitude = abs(smaller) / abs(larger)
        let sign: Double = (smaller / larger) >= 0 ? 1.0 : -1.0

        return magnitude * sign
    }

    /// Calculate allowable stress based on DIN 15018 tables
    /// - Parameters:
    ///   - kappa: Stress ratio (-1 to +1)
    ///   - stress: Applied stress value
    ///   - notchFactor: KF (0-4)
    ///   - baseStress: sB0 material factor
    /// - Returns: Allowable stress
    private static func sigZ(kappa: Double, stress: Double, notchFactor: Int, baseStress: Double) -> Double {
        // Table values for different notch factors
        let szul: [Double] = [84, 75, 63, 45, 27]  // KF = 0,1,2,3,4
        let sDZ0: [Double] = szul.map { (5.0/3.0) * $0 }

        guard notchFactor >= 0, notchFactor < szul.count else {
            return szul[0]  // Default to KF=0
        }

        let val: Double

        if kappa <= 0 && stress >= 0 {
            // Tension with stress reversal
            val = szul[notchFactor] / (1.0 - 0.5 * kappa)
        } else if kappa <= 0 && stress < 0 {
            // Compression with stress reversal
            val = -szul[notchFactor] / (1.0 - 0.5 * kappa)
        } else if kappa > 0 && stress >= 0 {
            // Pulsating tension
            val = sDZ0[notchFactor] / (1.0 + 2.0 * kappa)
        } else {
            // Pulsating compression
            val = -sDZ0[notchFactor] / (1.0 + 2.0 * kappa)
        }

        // Scale by base stress factor
        return val * baseStress / 490.0
    }

    // MARK: - Criterium Protocol

    public func calculateSafetyFactor(stress: Double, material: Material) -> Double {
        // Simplified single-stress interface
        // For full analysis, use calculateBW method
        let allowableStress = Self.sigZ(
            kappa: 0,  // Assume fully reversed
            stress: stress,
            notchFactor: 2,  // Moderate notch
            baseStress: material.baseStress
        )
        return abs(allowableStress / stress)
    }
}
