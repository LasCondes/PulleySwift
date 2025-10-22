import Foundation
import Accelerate

/// Finite element assembly and solver
/// Converted from C++ FEassembly in FEassembly.h
public final class FEAssembly {
    // Elements and nodes
    private var elements: [Element] = []
    private var nodes: [Node] = []

    // System matrices and vectors
    private var stiffnessMatrix: SparseMatrix?
    private var systemMatrix: SparseMatrix?
    private var externalForces: Vector?
    private var rightHandSide: Vector?
    private var solution: Vector?

    // System size
    private var numberOfVariables: Int = 0
    private var numberOfEquations: Int = 0

    public init() {}

    /// Clear all elements, nodes, and system data
    public func clear() {
        // Reset indices in all nodes
        for element in elements {
            for node in element.nodes {
                node.resetIndices()
            }
        }

        // Clear collections
        elements.removeAll()
        nodes.removeAll()
        stiffnessMatrix = nil
        systemMatrix = nil
        externalForces = nil
        rightHandSide = nil
        solution = nil
        numberOfVariables = 0
        numberOfEquations = 0
    }

    /// Add an element to the assembly
    public func addElement(_ element: Element) {
        elements.append(element)

        // Add all nodes from this element
        for node in element.nodes {
            nodes.append(node)
        }
    }

    /// Get number of variables (DOFs) in the system
    public func variableCount() -> Int {
        return numberOfVariables
    }

    /// Get number of equations
    public func equationCount() -> Int {
        return numberOfEquations
    }

    /// Assign global indices to node displacements
    private func assignIndices() {
        var currentIndex = 0

        // Visit all nodes and assign unique indices to each DOF
        // Use a set to track nodes we've already indexed
        var indexedNodes = Set<ObjectIdentifier>()

        for element in elements {
            for node in element.nodes {
                let nodeID = ObjectIdentifier(node)

                if !indexedNodes.contains(nodeID) {
                    // Assign indices for this node's displacements
                    for dof in 0..<node.numberOfDisplacements {
                        node.setIndex(currentIndex, at: dof)
                        currentIndex += 1
                    }
                    indexedNodes.insert(nodeID)
                }
            }
        }

        numberOfVariables = currentIndex
        numberOfEquations = currentIndex
    }

    /// Assemble global stiffness matrix and load vector
    public func assemble(mode: Int) {
        // Assign global indices to DOFs
        assignIndices()

        guard numberOfVariables > 0 else {
            print("Warning: No variables to assemble")
            return
        }

        // Initialize system matrices and vectors
        stiffnessMatrix = SparseMatrix(rows: numberOfEquations, columns: numberOfVariables)
        externalForces = Vector.zero(size: numberOfEquations)

        // Assemble contributions from each element
        for element in elements {
            assembleElement(element, mode: mode)
        }

        // Set system matrix to stiffness matrix (before boundary conditions)
        systemMatrix = stiffnessMatrix
        rightHandSide = externalForces
    }

    /// Assemble a single element's contribution
    private func assembleElement(_ element: Element, mode: Int) {
        // Get node indices
        let nodeIndices = element.nodes.flatMap { node in
            (0..<node.numberOfDisplacements).map { node.index(at: $0) }
        }

        // Check if element provides stiffness matrix directly
        if let elementK = element.computeElementStiffness() {
            // Use direct stiffness method
            for (i, globalI) in nodeIndices.enumerated() {
                guard globalI >= 0 else { continue }

                for (j, globalJ) in nodeIndices.enumerated() {
                    guard globalJ >= 0 else { continue }
                    guard i < elementK.rows && j < elementK.columns else { continue }

                    stiffnessMatrix?.add(value: elementK[i, j], at: globalI, globalJ)
                }
            }
        } else {
            // Use transfer matrix method
            let (transferMatrix, loadVector) = element.computeTransferMatrixAndLoad()

            // Add element contributions to global matrix and vector
            for (i, globalI) in nodeIndices.enumerated() {
                guard globalI >= 0 else { continue }

                // Add to load vector
                if var extForces = externalForces, i < loadVector.count {
                    extForces[globalI] = extForces[globalI] + loadVector[i]
                    externalForces = extForces
                }

                // Add to stiffness matrix (convert transfer matrix to stiffness)
                for (j, globalJ) in nodeIndices.enumerated() {
                    guard globalJ >= 0, i < transferMatrix.count, j < transferMatrix[i].count else { continue }

                    // TODO: Proper conversion from transfer matrix to stiffness matrix
                    stiffnessMatrix?.add(value: transferMatrix[i][j], at: globalI, globalJ)
                }
            }
        }
    }

    /// Solve the assembled system using LAPACK
    public func solve() -> Bool {
        guard let matrix = systemMatrix,
              let rhs = rightHandSide else {
            print("Error: System not assembled")
            return false
        }

        // Convert sparse matrix to dense
        let denseMatrix = matrix.toDense()

        // LAPACK solves Ax = b where A is the coefficient matrix
        // Convert to column-major order (LAPACK expects column-major)
        var AcolMajor = [Double](repeating: 0.0, count: numberOfEquations * numberOfEquations)
        for i in 0..<numberOfEquations {
            for j in 0..<numberOfEquations {
                AcolMajor[j * numberOfEquations + i] = denseMatrix[i, j]
            }
        }

        // Copy RHS (will be overwritten with solution)
        var b = rhs.flattenedData

        // LAPACK parameters (must be var for inout)
        var n = Int32(numberOfEquations)
        var nrhs = Int32(1)  // Number of right-hand sides
        var lda = Int32(numberOfEquations)  // Leading dimension of A
        var ldb = Int32(numberOfEquations)  // Leading dimension of b
        var ipiv = [Int32](repeating: 0, count: numberOfEquations)  // Pivot indices
        var info = Int32(0)

        // Solve using dgesv (general linear system solver)
        // dgesv computes the solution to A*X = B using LU factorization
        dgesv_(&n, &nrhs, &AcolMajor, &lda, &ipiv, &b, &ldb, &info)

        if info == 0 {
            // Success
            solution = Vector(data: b)
            return true
        } else if info < 0 {
            print("Error: LAPACK dgesv parameter \(-info) had an illegal value")
            return false
        } else {
            print("Error: Matrix is singular, U(\(info),\(info)) is exactly zero")
            return false
        }
    }

    /// Get solution vector
    public func getSolution() -> Vector? {
        return solution
    }

    /// Apply point force at a specific DOF
    public func applyForce(_ force: Double, atDOF dof: Int) {
        guard var forces = externalForces, dof >= 0, dof < forces.size else {
            return
        }
        forces[dof] = forces[dof] + force
        externalForces = forces
        rightHandSide = forces
    }

    /// Apply moment at a specific DOF
    public func applyMoment(_ moment: Double, atDOF dof: Int) {
        // Moments are applied the same way as forces
        applyForce(moment, atDOF: dof)
    }

    /// Fix a DOF (set displacement to zero)
    public func fixDOF(_ dof: Int) {
        guard var matrix = systemMatrix,
              var rhs = rightHandSide,
              dof >= 0, dof < numberOfEquations else {
            return
        }

        // Zero out the row
        for j in 0..<numberOfVariables {
            matrix.set(value: 0.0, at: dof, j)
        }

        // Set diagonal to 1.0
        matrix.set(value: 1.0, at: dof, dof)

        // Set RHS to 0.0 (prescribed displacement)
        rhs[dof] = 0.0

        systemMatrix = matrix
        rightHandSide = rhs
    }

    /// Fix multiple DOFs
    public func fixDOFs(_ dofs: [Int]) {
        for dof in dofs {
            fixDOF(dof)
        }
    }

    /// Prescribe displacement at a DOF
    public func prescribeDisplacement(_ displacement: Double, atDOF dof: Int) {
        guard var matrix = systemMatrix,
              var rhs = rightHandSide,
              dof >= 0, dof < numberOfEquations else {
            return
        }

        // Zero out the row
        for j in 0..<numberOfVariables {
            matrix.set(value: 0.0, at: dof, j)
        }

        // Set diagonal to 1.0
        matrix.set(value: 1.0, at: dof, dof)

        // Set RHS to prescribed value
        rhs[dof] = displacement

        systemMatrix = matrix
        rightHandSide = rhs
    }

    /// Get displacement at a DOF from solution
    public func getDisplacement(atDOF dof: Int) -> Double? {
        guard let sol = solution, dof >= 0, dof < sol.size else {
            return nil
        }
        return sol[dof]
    }

    /// Get all DOF indices for a node
    public func getDOFIndices(forNode node: Node) -> [Int] {
        var indices: [Int] = []
        for i in 0..<node.numberOfDisplacements {
            indices.append(node.index(at: i))
        }
        return indices
    }
}

/// Simple sparse matrix implementation
/// This is a basic implementation - could be optimized significantly
class SparseMatrix {
    let rows: Int
    let columns: Int
    private var entries: [Int: [Int: Double]] = [:]

    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
    }

    /// Add value at position (row, col)
    func add(value: Double, at row: Int, _ col: Int) {
        guard row >= 0, row < rows, col >= 0, col < columns else { return }

        if entries[row] == nil {
            entries[row] = [:]
        }

        let currentValue = entries[row]?[col] ?? 0.0
        entries[row]?[col] = currentValue + value
    }

    /// Get value at position (row, col)
    func get(at row: Int, _ col: Int) -> Double {
        return entries[row]?[col] ?? 0.0
    }

    /// Set value at position (row, col)
    func set(value: Double, at row: Int, _ col: Int) {
        guard row >= 0, row < rows, col >= 0, col < columns else { return }

        if entries[row] == nil {
            entries[row] = [:]
        }

        entries[row]?[col] = value
    }

    /// Convert to dense matrix
    func toDense() -> Matrix {
        var matrix = Matrix.zero(rows: rows, columns: columns)

        for (row, cols) in entries {
            for (col, value) in cols {
                matrix[row, col] = value
            }
        }

        return matrix
    }

    /// Get number of non-zero entries
    var nonZeroCount: Int {
        return entries.values.reduce(0) { $0 + $1.count }
    }
}
