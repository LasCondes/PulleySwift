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
        // Placeholder implementation
        // Full implementation requires transfer matrix integration
        let size = 8  // 4 displacements × 2 nodes
        let matrix = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        let load = Array(repeating: 0.0, count: size)

        return (matrix: matrix, load: load)
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

    /// Compute ODE matrix Hm at position z
    /// This is a placeholder - full implementation requires TMB equations
    private func computeHm(at radius: Double) -> Matrix {
        let size = 8
        var hm = Matrix.zero(rows: size, columns: size)

        // Placeholder - actual implementation needs:
        // - TMB differential equations for disk bending
        // - Material stiffness terms
        // - Geometric terms based on thickness variation

        return hm
    }

    /// Compute load vector at position z
    private func computeLoad(at radius: Double) -> Vector {
        var load = Vector.zero(size: 8)

        if hasGravity {
            // Add gravity load contribution
            // Placeholder - actual calculation depends on mode shape
            let t = thickness(at: radius)
            let gravityLoad = gravity * density * t

            // Distribute to appropriate DOFs
            // This is simplified - actual distribution depends on shape functions
            load[2] = gravityLoad  // w displacement
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
