import Foundation
import PulleyCore

/// Shaft element for beam and bar analysis (combined bending and torsion)
/// Converted from C++ cShaftElement in cShaftElement.h
public final class ShaftElement: Element {
    public let elementType: ElementType = .beam

    /// Nodes for this element (2 nodes: beginning and end)
    public let nodes: [Node]

    // Geometric properties
    private let diameter: Double
    private let axialPositionStart: Double  // z0
    private let axialPositionEnd: Double    // zL

    // Material properties
    private let youngsModulus: Double    // E
    private let poissonsRatio: Double    // nu

    // Derived properties
    private let radius: Double
    private let area: Double
    private let shearModulus: Double     // G = E / (2(1+nu))
    private let momentOfInertia: Double  // I = π*d^4/64

    // Computation options
    private let mode: Int  // Fourier mode number

    // Shaft model type
    public enum ShaftModel {
        case eulerBernoulli     // Model 0 - neglects shear deformation
        case timoshenko         // Model 1 - includes shear deformation
    }
    private let model: ShaftModel

    public init(
        diameter: Double,
        axialPositionStart: Double,
        axialPositionEnd: Double,
        youngsModulus: Double,
        poissonsRatio: Double,
        mode: Int,
        model: ShaftModel = .timoshenko
    ) {
        self.diameter = diameter
        self.axialPositionStart = axialPositionStart
        self.axialPositionEnd = axialPositionEnd
        self.youngsModulus = youngsModulus
        self.poissonsRatio = poissonsRatio
        self.mode = mode
        self.model = model

        // Calculate derived properties
        self.radius = diameter / 2.0
        self.area = .pi * radius * radius
        self.shearModulus = youngsModulus / (2.0 * (1.0 + poissonsRatio))
        self.momentOfInertia = .pi * pow(diameter, 4) / 64.0

        // Create two nodes
        // Node displacement order: w, gamma (beam), u, beta (bar)
        // w = transverse displacement
        // gamma = rotation due to bending
        // u = axial displacement
        // beta = rotation due to torsion
        self.nodes = [
            Node(numberOfDisplacements: 4),
            Node(numberOfDisplacements: 4)
        ]
    }

    /// Get element length in axial direction
    public var length: Double {
        return axialPositionEnd - axialPositionStart
    }

    // MARK: - Element Protocol

    public func numberOfDisplacements() -> Int {
        return 4  // w, gamma, u, beta
    }

    public func computeTransferMatrixAndLoad() -> (matrix: [[Double]], load: [Double]) {
        // Shaft has constant properties along length
        // Use constant integration method
        let H = computeHm(at: axialPositionStart)
        let T = TransferMatrixIntegrator.integrateConstant(H: H, length: length)

        // Convert to array
        var matrixArray: [[Double]] = []
        for i in 0..<T.rows {
            var row: [Double] = []
            for j in 0..<T.columns {
                row.append(T[i, j])
            }
            matrixArray.append(row)
        }

        let load = Array(repeating: 0.0, count: 8)
        return (matrix: matrixArray, load: load)
    }

    // MARK: - Shaft-Specific Methods

    /// Compute beam stiffness matrix (4x4 for w, gamma at each node)
    public func computeBeamStiffness() -> Matrix {
        let L = length
        var K = Matrix.zero(rows: 4, columns: 4)

        switch model {
        case .eulerBernoulli:
            // Euler-Bernoulli beam stiffness matrix
            let EI = youngsModulus * momentOfInertia
            let factor = EI / pow(L, 3)

            K[0, 0] = 12.0 * factor
            K[0, 1] = 6.0 * L * factor
            K[0, 2] = -12.0 * factor
            K[0, 3] = 6.0 * L * factor

            K[1, 0] = 6.0 * L * factor
            K[1, 1] = 4.0 * L * L * factor
            K[1, 2] = -6.0 * L * factor
            K[1, 3] = 2.0 * L * L * factor

            K[2, 0] = -12.0 * factor
            K[2, 1] = -6.0 * L * factor
            K[2, 2] = 12.0 * factor
            K[2, 3] = -6.0 * L * factor

            K[3, 0] = 6.0 * L * factor
            K[3, 1] = 2.0 * L * L * factor
            K[3, 2] = -6.0 * L * factor
            K[3, 3] = 4.0 * L * L * factor

        case .timoshenko:
            // Timoshenko beam includes shear deformation
            let EI = youngsModulus * momentOfInertia
            let kappa = 0.9  // Shear correction factor for circular cross-section
            let GA = kappa * shearModulus * area
            let phi = (12.0 * EI) / (GA * L * L)

            let factor = EI / (L * L * L * (1.0 + phi))

            K[0, 0] = 12.0 * factor
            K[0, 1] = 6.0 * L * factor
            K[0, 2] = -12.0 * factor
            K[0, 3] = 6.0 * L * factor

            K[1, 0] = 6.0 * L * factor
            K[1, 1] = (4.0 + phi) * L * L * factor
            K[1, 2] = -6.0 * L * factor
            K[1, 3] = (2.0 - phi) * L * L * factor

            K[2, 0] = -12.0 * factor
            K[2, 1] = -6.0 * L * factor
            K[2, 2] = 12.0 * factor
            K[2, 3] = -6.0 * L * factor

            K[3, 0] = 6.0 * L * factor
            K[3, 1] = (2.0 - phi) * L * L * factor
            K[3, 2] = -6.0 * L * factor
            K[3, 3] = (4.0 + phi) * L * L * factor
        }

        return K
    }

    /// Compute bar stiffness matrix (2x2 for u, beta at each node)
    public func computeBarStiffness() -> Matrix {
        let L = length
        var K = Matrix.zero(rows: 2, columns: 2)

        // Axial stiffness
        let EA = youngsModulus * area
        K[0, 0] = EA / L
        K[0, 1] = -EA / L
        K[1, 0] = -EA / L
        K[1, 1] = EA / L

        return K
    }

    /// Compute torsional stiffness
    public func computeTorsionalStiffness() -> Double {
        let J = .pi * pow(diameter, 4) / 32.0  // Polar moment of inertia
        let GJ = shearModulus * J
        return GJ / length
    }

    /// Compute bar output (axial and torsional)
    public func computeBarOutput(at z: Double) -> (u: Double, beta: Double, Nx: Double, Mt: Double) {
        // Placeholder - actual computation requires node displacements
        return (u: 0.0, beta: 0.0, Nx: 0.0, Mt: 0.0)
    }

    /// Compute beam output (bending)
    public func computeBeamOutput(at z: Double) -> (w: Double, gamma: Double, V: Double, Mx: Double) {
        // Placeholder - actual computation requires node displacements
        return (w: 0.0, gamma: 0.0, V: 0.0, Mx: 0.0)
    }

    // MARK: - Private Methods

    /// Compute ODE matrix Hm at position z
    /// Implements shaft differential equations for beam + bar
    private func computeHm(at z: Double) -> Matrix {
        let size = 8
        var Hm = Matrix.zero(rows: size, columns: size)

        let EI = youngsModulus * momentOfInertia
        let EA = youngsModulus * area
        let J = .pi * pow(diameter, 4) / 32.0  // Polar moment
        let GJ = shearModulus * J

        // State vector: [w, gamma, u, beta, V, M, N, T]
        // where V=shear, M=moment, N=axial force, T=torque

        switch model {
        case .eulerBernoulli:
            // Euler-Bernoulli beam: w'' = gamma, gamma'' = M/EI
            // Equilibrium: V' = 0, M' = -V
            Hm[0, 1] = 1.0           // dw/dz = gamma
            Hm[1, 5] = 1.0 / EI      // dgamma/dz = M/EI
            Hm[4, 4] = 0.0           // dV/dz = 0 (no distributed load)
            Hm[5, 4] = -1.0          // dM/dz = -V

        case .timoshenko:
            // Timoshenko beam: includes shear deformation
            // w' = gamma - V/(kappa*GA)
            // gamma' = M/EI
            // V' = 0, M' = -V
            let kappa = 0.9  // Shear correction factor
            let GA = kappa * shearModulus * area

            Hm[0, 1] = 1.0           // dw/dz = gamma - V/(kappa*GA) term
            Hm[0, 4] = -1.0 / GA     // shear deformation contribution
            Hm[1, 5] = 1.0 / EI      // dgamma/dz = M/EI
            Hm[4, 4] = 0.0           // dV/dz = 0
            Hm[5, 4] = -1.0          // dM/dz = -V
        }

        // Axial part (bar): u' = N/EA, N' = 0
        Hm[2, 6] = 1.0 / EA          // du/dz = N/EA
        Hm[6, 6] = 0.0               // dN/dz = 0

        // Torsion part: beta' = T/GJ, T' = 0
        Hm[3, 7] = 1.0 / GJ          // dbeta/dz = T/GJ
        Hm[7, 7] = 0.0               // dT/dz = 0

        return Hm
    }

    /// Compute transfer matrix T at position z
    private func computeT(at z: Double) -> Matrix {
        let size = 8
        let t = Matrix.identity(size: size)

        // Placeholder - transfer matrix relates state at position z to initial state

        return t
    }
}

/// Shaft model output structure
public struct ShaftModelOutput {
    public let dispU: Double        // Axial displacement
    public let dispBeta: Double     // Angular deflection - torsion
    public let dispW: Double        // Transverse displacement
    public let dispGamma: Double    // Angular bending

    public let Nx: Double           // Axial force
    public let V: Double            // Shear force

    public let Mx: Double           // Bending moment
    public let Mt: Double           // Torsional moment

    public init(
        dispU: Double, dispBeta: Double, dispW: Double, dispGamma: Double,
        Nx: Double, V: Double, Mx: Double, Mt: Double
    ) {
        self.dispU = dispU
        self.dispBeta = dispBeta
        self.dispW = dispW
        self.dispGamma = dispGamma
        self.Nx = Nx
        self.V = V
        self.Mx = Mx
        self.Mt = Mt
    }
}
