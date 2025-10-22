import Foundation
import PulleyCore

/// Shell element for cylindrical shell analysis
/// Converted from C++ cShellElement in cShellElement.h
public final class ShellElement: Element {
    public let elementType: ElementType = .shell

    /// Nodes for this element (2 nodes: beginning and end)
    public let nodes: [Node]

    // Geometric properties
    private let radius: Double           // R
    private let thickness: Double        // t (constant thickness)
    private let axialPositionStart: Double  // z0
    private let axialPositionEnd: Double    // zL

    // Material properties
    private let youngsModulus: Double    // E
    private let poissonsRatio: Double    // nu

    // Computation options
    private let useNumericalIntegration: Bool
    private let mode: Int  // Fourier mode number

    // Shell model type
    public enum ShellModel {
        case ventselKrauthammer        // Model 0
        case timoshenkoWoinowskyKrieger  // Model 1
    }
    private let model: ShellModel

    // Applied loads
    private var hasGravity: Bool = false
    private var gravity: Double = 0.0
    private var density: Double = 0.0
    private var isUnderBelt: Bool = false

    // Cached calculations
    private var hmCalculated: Bool = false
    private var cachedHm: Matrix?

    public init(
        radius: Double,
        thickness: Double,
        axialPositionStart: Double,
        axialPositionEnd: Double,
        youngsModulus: Double,
        poissonsRatio: Double,
        useNumericalIntegration: Bool,
        mode: Int,
        model: ShellModel = .ventselKrauthammer
    ) {
        self.radius = radius
        self.thickness = thickness
        self.axialPositionStart = axialPositionStart
        self.axialPositionEnd = axialPositionEnd
        self.youngsModulus = youngsModulus
        self.poissonsRatio = poissonsRatio
        self.useNumericalIntegration = useNumericalIntegration
        self.mode = mode
        self.model = model

        // Create two nodes
        // Node displacement order: u, v, w, phi
        self.nodes = [
            Node(numberOfDisplacements: 4),
            Node(numberOfDisplacements: 4)
        ]
    }

    /// Get element length in axial direction
    public var length: Double {
        return axialPositionEnd - axialPositionStart
    }

    /// Add gravity loading
    public func addGravity(_ gravityValue: Double, density densityValue: Double) {
        guard mode == -1 else {
            // Gravity only applied to mode -1
            return
        }
        self.hasGravity = true
        self.gravity = gravityValue
        self.density = densityValue
    }

    /// Mark if element is under the belt
    public func setUnderBelt(_ underBelt: Bool) {
        self.isUnderBelt = underBelt
    }

    /// Check if element has applied loads
    public func hasAppliedLoad() -> Bool {
        return hasGravity || isUnderBelt
    }

    // MARK: - Element Protocol

    public func numberOfDisplacements() -> Int {
        return 4  // u, v, w, phi
    }

    public func computeTransferMatrixAndLoad() -> (matrix: [[Double]], load: [Double]) {
        // For shell, Hm is constant (doesn't vary with z)
        // Use constant integration method
        let H = computeHm(at: axialPositionStart)
        let T = TransferMatrixIntegrator.integrateConstant(H: H, length: length)

        // Integrate load if present
        var load = Vector.zero(size: 8)
        if hasAppliedLoad() {
            // Simple integration for constant load
            let L = computeLoad(at: (axialPositionStart + axialPositionEnd) / 2.0)
            load = L.flattenedData.map { $0 * length }
                .enumerated()
                .reduce(into: Vector.zero(size: 8)) { result, element in
                    result[element.offset] = element.element
                }
        }

        // Convert Matrix to [[Double]]
        var matrixArray: [[Double]] = []
        for i in 0..<T.rows {
            var row: [Double] = []
            for j in 0..<T.columns {
                row.append(T[i, j])
            }
            matrixArray.append(row)
        }

        return (matrix: matrixArray, load: load.flattenedData)
    }

    // MARK: - Private Methods

    /// Compute ODE matrix Hm at position z
    /// Implements shell theory differential equations (Ventsel-Krauthammer or TWK)
    /// Based on Equations 47-40 from the FEA documentation
    private func computeHm(at z: Double) -> Matrix {
        if hmCalculated, let cached = cachedHm {
            return cached
        }

        let D = youngsModulus * pow(thickness, 3) / (12.0 * (1.0 - pow(poissonsRatio, 2)))
        let n = Double(mode)
        let R = radius
        let t = thickness

        // Build 8x8 Hm matrix
        var Hm = Matrix.zero(rows: 8, columns: 8)

        switch model {
        case .ventselKrauthammer:
            // Ventsel-Krauthammer shell model (Equations 47-40)

            // An matrix (4x4)
            var An = Matrix.zero(rows: 4, columns: 4)
            An[1, 0] = youngsModulus * t * n * R / (youngsModulus * t * R * R + 4.0 * (1.0 - poissonsRatio * poissonsRatio) * D)
            An[0, 1] = -poissonsRatio * n / R
            An[3, 1] = -poissonsRatio * n / (R * R)
            An[0, 2] = -poissonsRatio / R
            An[3, 2] = -poissonsRatio * n * n / (R * R)
            An[1, 3] = 4.0 * (1.0 - poissonsRatio * poissonsRatio) * n * D / (youngsModulus * t * R * R + 4.0 * (1.0 - poissonsRatio * poissonsRatio) * D)
            An[2, 3] = -1.0

            // Bn matrix (4x4)
            var Bn = Matrix.zero(rows: 4, columns: 4)
            Bn[0, 0] = (1.0 - poissonsRatio * poissonsRatio) / (2.0 * Double.pi * R * youngsModulus * t)
            Bn[1, 1] = (1.0 + poissonsRatio) * R / (Double.pi * youngsModulus * t * R * R + 4.0 * Double.pi * (1.0 - poissonsRatio * poissonsRatio) * D)
            Bn[3, 3] = 1.0 / (2.0 * Double.pi * R * D)

            // Cn matrix (4x4)
            var Cn = Matrix.zero(rows: 4, columns: 4)
            Cn[0, 0] = 4.0 * Double.pi * (1.0 - poissonsRatio) * n * n * youngsModulus * t * D / (youngsModulus * t * R * R * R + 4.0 * (1.0 - poissonsRatio * poissonsRatio) * R * D)
            Cn[3, 0] = -4.0 * Double.pi * (1.0 - poissonsRatio) * n * n * youngsModulus * t * D / (youngsModulus * t * R * R + 4.0 * (1.0 - poissonsRatio * poissonsRatio) * D)
            Cn[1, 1] = 2.0 * Double.pi * n * n * youngsModulus * t / R + 2.0 * Double.pi * (1.0 - poissonsRatio * poissonsRatio) * n * n * D / (R * R * R)
            Cn[2, 1] = 2.0 * Double.pi * n * youngsModulus * t / R + 2.0 * Double.pi * (1.0 - poissonsRatio * poissonsRatio) * n * n * n * D / (R * R * R)
            Cn[1, 2] = Cn[2, 1]
            Cn[2, 2] = 2.0 * Double.pi * youngsModulus * t / R + 2.0 * Double.pi * (1.0 - poissonsRatio * poissonsRatio) * n * n * n * n * D / (R * R * R)
            Cn[0, 3] = Cn[3, 0]
            Cn[3, 3] = 4.0 * Double.pi * n * n * (1.0 - poissonsRatio) * D / R - 16.0 * Double.pi * (1.0 + poissonsRatio) * (1.0 - poissonsRatio * poissonsRatio) * n * n * D * D / (youngsModulus * t * R * R * R + 4.0 * (1.0 - poissonsRatio * poissonsRatio) * R * D)

            // Dn = -An^T
            var Dn = Matrix.zero(rows: 4, columns: 4)
            for i in 0..<4 {
                for j in 0..<4 {
                    Dn[i, j] = -An[j, i]
                }
            }

            // Assemble into 8x8
            for i in 0..<4 {
                for j in 0..<4 {
                    Hm[i, j] = An[i, j]
                    Hm[i, j + 4] = Bn[i, j]
                    Hm[i + 4, j] = Cn[i, j]
                    Hm[i + 4, j + 4] = Dn[i, j]
                }
            }

        case .timoshenkoWoinowskyKrieger:
            // TWK model (Equation C30)
            // Simpler, sparser formulation than Ventsel-Krauthammer

            let n = Double(mode)
            let R = radius
            let t = thickness
            let nu = poissonsRatio
            let E = youngsModulus

            // TWK matrix is sparse - only 18 non-zero entries
            Hm[1, 0] = n / R
            Hm[0, 1] = -nu * n / R

            Hm[0, 2] = -nu / R
            Hm[3, 2] = -nu * n * n / (R * R)

            Hm[2, 3] = -1.0
            Hm[7, 3] = Double.pi * E * t * t * t * n * n / (3.0 * (1.0 + nu) * R)
            Hm[0, 4] = (1.0 - nu * nu) / (2.0 * Double.pi * E * t * R)

            Hm[1, 5] = (1.0 + nu) / (Double.pi * E * t * R)
            Hm[4, 5] = -n / R
            Hm[7, 6] = 1.0
            Hm[3, 7] = 6.0 * (1.0 - nu * nu) / (Double.pi * E * t * t * t * R)

            Hm[5, 1] = 2.0 * Double.pi * E * t * n * n / R
            Hm[5, 2] = 2.0 * Double.pi * E * t * n / R
            Hm[5, 4] = nu * n / R

            Hm[6, 1] = 2.0 * Double.pi * E * t * n / R
            Hm[6, 2] = 2.0 * Double.pi * E * t / R * (1.0 + t * t * n * n * n * n / (12.0 * R * R))
            Hm[6, 4] = nu / R
            Hm[6, 7] = nu * n * n / (R * R)
        }

        cachedHm = Hm
        hmCalculated = true

        return Hm
    }

    /// Compute load vector at position z
    /// Implements shell loading from gravity and belt pressure
    private func computeLoad(at z: Double) -> Vector {
        var load = Vector.zero(size: 8)

        if hasGravity {
            // Gravity force (distributed over circumference)
            // From C++ implementation: load on indices 5 and 6
            let innR = radius - thickness / 2.0
            let outR = radius + thickness / 2.0
            let area = Double.pi * (outR * outR - innR * innR)
            let gravityForce = area * density * gravity

            load[5] = gravityForce
            load[6] = gravityForce
        }

        if isUnderBelt {
            // Belt loading - radial and tangential components
            // I(fzm, ftm, frm) = [-2πR*fzm, -2πR*ftm, -2πR*frm]
            // Actual belt pressures would come from load calculation
            // Placeholder for now - full implementation needs belt tension model
        }

        return load
    }

    /// Compute J matrix (mode-dependent coupling matrix)
    private func computeJ(mode m: Int) -> Matrix {
        let size = 8
        let j = Matrix.zero(rows: size, columns: size)

        // Placeholder - J matrix depends on shell model and Fourier mode
        // This matrix couples different displacement components

        return j
    }
}

/// Shell model output structure
public struct ShellModelOutput {
    public let dispU: Double
    public let dispV: Double
    public let dispW: Double
    public let dispTheta: Double
    public let Nx: Double   // Axial force
    public let Nt: Double   // Circumferential force
    public let Nxt: Double  // Shear force
    public let Mx: Double   // Axial moment
    public let Mt: Double   // Circumferential moment
    public let Mxt: Double  // Torsional moment
    public let Q1: Double   // Transverse shear force 1
    public let Q2: Double   // Transverse shear force 2

    public init(
        dispU: Double, dispV: Double, dispW: Double, dispTheta: Double,
        Nx: Double, Nt: Double, Nxt: Double,
        Mx: Double, Mt: Double, Mxt: Double,
        Q1: Double, Q2: Double
    ) {
        self.dispU = dispU
        self.dispV = dispV
        self.dispW = dispW
        self.dispTheta = dispTheta
        self.Nx = Nx
        self.Nt = Nt
        self.Nxt = Nxt
        self.Mx = Mx
        self.Mt = Mt
        self.Mxt = Mxt
        self.Q1 = Q1
        self.Q2 = Q2
    }
}
