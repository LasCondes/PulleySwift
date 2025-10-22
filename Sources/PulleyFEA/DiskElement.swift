import Foundation
import PulleyCore

/// Represents one single Fourier component of a TMB plate element, subject to bending
/// Converted from C++ cDiskElement in cDiskElement.h
public final class DiskElement: Element {
    public let elementType: ElementType = .disk

    /// Nodes for this element (2 nodes: beginning and end)
    public let nodes: [Node]

    // Geometric properties
    private let innerRadius: Double  // r0
    private let outerRadius: Double  // rL

    // Material properties
    private let youngsModulus: Double      // E
    private let poissonsRatio: Double      // nu

    // Thickness model parameters
    private var thicknessBegin: Double
    private var thicknessEnd: Double
    private var thicknessLinear: Bool
    private var thicknessC: Double  // turbine thickness c
    private var thicknessP: Double  // turbine thickness p

    // Computation options
    private let useNumericalIntegration: Bool
    private let mode: Int  // Fourier mode number

    // Applied loads
    private var hasGravity: Bool = false
    private var gravity: Double = 0.0
    private var density: Double = 0.0

    public init(
        innerRadius: Double,
        outerRadius: Double,
        thicknessBegin: Double,
        thicknessEnd: Double,
        youngsModulus: Double,
        poissonsRatio: Double,
        useNumericalIntegration: Bool,
        mode: Int
    ) {
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.thicknessBegin = thicknessBegin
        self.thicknessEnd = thicknessEnd
        self.youngsModulus = youngsModulus
        self.poissonsRatio = poissonsRatio
        self.useNumericalIntegration = useNumericalIntegration
        self.mode = mode

        // Initialize with linear thickness model
        self.thicknessLinear = true
        self.thicknessC = 0.0
        self.thicknessP = 0.0

        // Create two nodes (beginning and end)
        // Node displacement order: u, v, w, phi
        self.nodes = [
            Node(numberOfDisplacements: 4),
            Node(numberOfDisplacements: 4)
        ]

        // Set up thickness interpolation
        setupThicknessModel()
    }

    /// Set thickness model (linear or power-law)
    public func setThickness(begin: Double, end: Double, linear: Bool = true) {
        self.thicknessBegin = begin
        self.thicknessEnd = end
        self.thicknessLinear = linear
        setupThicknessModel()
    }

    /// Calculate thickness at given radius
    public func thickness(at radius: Double) -> Double {
        if thicknessLinear {
            // Linear interpolation: t = c*r + p
            return thicknessC * radius + thicknessP
        } else {
            // Power law: t = c * r^p (turbine interpolation)
            return thicknessC * pow(radius, thicknessP)
        }
    }

    /// Add gravity loading
    public func addGravity(_ gravityValue: Double, density densityValue: Double) {
        self.hasGravity = true
        self.gravity = gravityValue
        self.density = densityValue
    }

    /// Check if element has applied loads
    public func hasAppliedLoad() -> Bool {
        return hasGravity
    }

    // MARK: - Element Protocol

    public func numberOfDisplacements() -> Int {
        return 4  // u, v, w, phi
    }

    public func computeTransferMatrixAndLoad() -> (matrix: [[Double]], load: [Double]) {
        // Integrate transfer matrix using logarithmic spacing
        let result = TransferMatrixIntegrator.integrate(
            Hm: { [weak self] z in self?.computeHm(at: z) ?? Matrix.zero(rows: 8, columns: 8) },
            load: { [weak self] z in self?.computeLoad(at: z) ?? Vector.zero(size: 8) },
            start: innerRadius,
            end: outerRadius,
            hasLoad: hasAppliedLoad()
        )

        // Convert Matrix to [[Double]]
        var matrixArray: [[Double]] = []
        for i in 0..<result.transferMatrix.rows {
            var row: [Double] = []
            for j in 0..<result.transferMatrix.columns {
                row.append(result.transferMatrix[i, j])
            }
            matrixArray.append(row)
        }

        return (matrix: matrixArray, load: result.loadVector.flattenedData)
    }

    // MARK: - Private Methods

    private func setupThicknessModel() {
        if thicknessLinear {
            // Linear model: t = c*r + p
            // At r = innerRadius: t = thicknessBegin
            // At r = outerRadius: t = thicknessEnd
            let deltaR = outerRadius - innerRadius
            guard deltaR > 0 else {
                thicknessC = 0.0
                thicknessP = thicknessBegin
                return
            }

            thicknessC = (thicknessEnd - thicknessBegin) / deltaR
            thicknessP = thicknessBegin - thicknessC * innerRadius
        } else {
            // Power law model: t = c * r^p
            // Turbine interpolation for large elements
            guard thicknessBegin > 0 && thicknessEnd > 0 && innerRadius > 0 else {
                thicknessC = thicknessBegin
                thicknessP = 0.0
                return
            }

            thicknessP = log(thicknessEnd / thicknessBegin) / log(outerRadius / innerRadius)
            thicknessC = thicknessBegin / pow(innerRadius, thicknessP)
        }
    }

    /// Compute ODE matrix Hm at position r (radius)
    /// Implements TMB (Transfer Matrix Bending) equations for disk
    /// Based on Equations 95-99 from the FEA documentation
    private func computeHm(at r: Double) -> Matrix {
        let t = thickness(at: r)
        let D = youngsModulus * pow(t, 3) / (12.0 * (1.0 - pow(poissonsRatio, 2)))  // Bending stiffness
        let n = Double(mode)  // Fourier mode number

        // Equation 96: An matrix
        var An = Matrix.zero(rows: 4, columns: 4)
        An[3, 0] = poissonsRatio * n * n / (r * r)
        An[1, 1] = 1.0 / r
        An[2, 1] = -poissonsRatio * n / r
        An[1, 2] = n / r
        An[2, 2] = -poissonsRatio / r
        An[0, 3] = 1.0
        An[3, 3] = -poissonsRatio / r

        // Equation 97: Bn matrix
        var Bn = Matrix.zero(rows: 4, columns: 4)
        Bn[1, 1] = (1.0 + poissonsRatio) / (Double.pi * youngsModulus * r * t)
        Bn[2, 2] = (1.0 - pow(poissonsRatio, 2)) / (2.0 * Double.pi * youngsModulus * r * t)
        Bn[3, 3] = 1.0 / (2.0 * Double.pi * D * r)

        // Equation 98: Cn matrix
        var Cn = Matrix.zero(rows: 4, columns: 4)
        Cn[0, 0] = 2.0 * Double.pi * (2.0 - 2.0 * poissonsRatio + n * n - poissonsRatio * poissonsRatio * n * n) * n * n * D / (r * r * r)
        Cn[3, 0] = 2.0 * Double.pi * (poissonsRatio * poissonsRatio + 2.0 * poissonsRatio - 3.0) * n * n * D / (r * r)
        Cn[1, 1] = 2.0 * Double.pi * n * n * youngsModulus * t / r
        Cn[2, 1] = 2.0 * Double.pi * n * youngsModulus * t / r
        Cn[1, 2] = Cn[2, 1]
        Cn[2, 2] = 2.0 * Double.pi * youngsModulus * t / r
        Cn[0, 3] = Cn[3, 0]
        Cn[3, 3] = 2.0 * Double.pi * (1.0 - poissonsRatio * poissonsRatio + 2.0 * n * n - 2.0 * n * n * poissonsRatio) * D / r

        // Equation 99: Dn matrix
        var Dn = Matrix.zero(rows: 4, columns: 4)
        Dn[3, 0] = -1.0
        Dn[1, 1] = -1.0 / r
        Dn[2, 1] = -n / r
        Dn[1, 2] = n * poissonsRatio / r
        Dn[2, 2] = poissonsRatio / r
        Dn[0, 3] = -poissonsRatio * n * n / (r * r)
        Dn[3, 3] = poissonsRatio / r

        // Equation 95: Assemble 8x8 matrix
        var Hm = Matrix.zero(rows: 8, columns: 8)

        // Top-left: An
        for i in 0..<4 {
            for j in 0..<4 {
                Hm[i, j] = An[i, j]
            }
        }

        // Top-right: Bn
        for i in 0..<4 {
            for j in 0..<4 {
                Hm[i, j + 4] = Bn[i, j]
            }
        }

        // Bottom-left: Cn
        for i in 0..<4 {
            for j in 0..<4 {
                Hm[i + 4, j] = Cn[i, j]
            }
        }

        // Bottom-right: Dn
        for i in 0..<4 {
            for j in 0..<4 {
                Hm[i + 4, j + 4] = Dn[i, j]
            }
        }

        return Hm
    }

    /// Compute load vector at position r (radius)
    /// Gravity loading for disk element
    private func computeLoad(at r: Double) -> Vector {
        var load = Vector.zero(size: 8)

        if hasGravity {
            // Gravity force distributed over disk
            // From C++ implementation: grav[5] and grav[6] for shear and radial directions
            let t = thickness(at: r)
            let loadMagnitude = t * 2.0 * r * Double.pi * gravity * density

            // Apply to force components (indices 4-7 are forces/moments)
            load[5] = loadMagnitude  // Shear force
            load[6] = loadMagnitude  // Radial force
        }

        return load
    }
}

/// Disk model output structure
public struct DiskModelOutput {
    public let dispU: Double
    public let dispV: Double
    public let dispW: Double
    public let dispTheta: Double
    public let Nr: Double  // Radial force
    public let Nt: Double  // Tangential force
    public let Nrt: Double // Shear force
    public let Mr: Double  // Radial moment
    public let Mt: Double  // Tangential moment
    public let Mrt: Double // Torsional moment
    public let Q1: Double  // Shear force 1
    public let Q2: Double  // Shear force 2

    public init(
        dispU: Double, dispV: Double, dispW: Double, dispTheta: Double,
        Nr: Double, Nt: Double, Nrt: Double,
        Mr: Double, Mt: Double, Mrt: Double,
        Q1: Double, Q2: Double
    ) {
        self.dispU = dispU
        self.dispV = dispV
        self.dispW = dispW
        self.dispTheta = dispTheta
        self.Nr = Nr
        self.Nt = Nt
        self.Nrt = Nrt
        self.Mr = Mr
        self.Mt = Mt
        self.Mrt = Mrt
        self.Q1 = Q1
        self.Q2 = Q2
    }
}
