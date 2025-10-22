import Foundation
import PulleyFEA
import PulleyCore

/// Example: Simple supported shaft with transverse load
/// A shaft of length 1000mm, diameter 50mm, simply supported at both ends
/// with a transverse force of 1000N applied at the center
///
/// Geometry:
/// |-------- 500mm --------|-------- 500mm --------|
/// ^                       ↓ 1000N                  ^
/// Support (w=0)           Load                     Support (w=0)
///
/// DOFs per node: w (transverse), gamma (rotation), u (axial), beta (torsion)

func runShaftExample() {
    print("=" * 60)
    print("SHAFT FEA EXAMPLE: Cantilever Beam with End Load")
    print("=" * 60)

    // Material properties (Steel)
    let E = 210000.0  // Young's modulus (MPa)
    let nu = 0.3      // Poisson's ratio
    let diameter = 50.0  // mm
    let length1 = 500.0  // mm (left element)
    let length2 = 500.0  // mm (right element)

    print("\nModel Parameters:")
    print("  Material: Steel")
    print("  Young's Modulus: \(E) MPa")
    print("  Poisson's Ratio: \(nu)")
    print("  Shaft Diameter: \(diameter) mm")
    print("  Total Length: \(length1 + length2) mm")
    print("  Elements: 2 (Timoshenko beam)")

    // Create FE assembly
    let assembly = FEAssembly()

    // For now, use a single element for simplicity
    // (Node sharing between elements needs to be implemented properly)
    let element = ShaftElement(
        diameter: diameter,
        axialPositionStart: 0.0,
        axialPositionEnd: length1 + length2,
        youngsModulus: E,
        poissonsRatio: nu,
        mode: 0,  // Mode 0 for static analysis
        model: .timoshenko
    )

    // Add element to assembly
    assembly.addElement(element)

    print("\nAssembling system...")
    assembly.assemble(mode: 0)

    let nDOF = assembly.variableCount()
    print("  Total DOFs: \(nDOF)")
    print("  Total Equations: \(assembly.equationCount())")

    // Node connectivity (single element with 2 nodes, 4 DOFs each)
    // Node 0: z=0 (left support)
    // Node 1: z=1000 (right support)

    let node0 = element.nodes[0]  // Left support
    let node1 = element.nodes[1]  // Right support

    print("\nNode Connectivity:")
    print("  Node 0 (z=0mm):    DOFs \(assembly.getDOFIndices(forNode: node0))")
    print("  Node 1 (z=1000mm): DOFs \(assembly.getDOFIndices(forNode: node1))")

    // Apply boundary conditions
    print("\nApplying Boundary Conditions:")

    // DOF ordering: [w, gamma, u, beta] for each node
    let node0DOFs = assembly.getDOFIndices(forNode: node0)
    let node1DOFs = assembly.getDOFIndices(forNode: node1)

    // Fixed end (cantilever): fix all DOFs at left end
    assembly.fixDOF(node0DOFs[0])  // w = 0
    assembly.fixDOF(node0DOFs[1])  // gamma = 0 (no rotation)
    assembly.fixDOF(node0DOFs[2])  // u = 0
    assembly.fixDOF(node0DOFs[3])  // beta = 0
    print("  Node 0: Fully fixed (cantilever support)")

    // Apply transverse load at free end
    let endForce = -1000.0  // N (downward)
    assembly.applyForce(endForce, atDOF: node1DOFs[0])  // Apply to w at node 1
    print("\nApplying Loads:")
    print("  Node 1 (free end): Transverse force = \(endForce) N")

    // Solve the system
    print("\nSolving...")
    let success = assembly.solve()

    if success {
        print("✓ Solution converged")
    } else {
        print("✗ Solution failed")
        return
    }

    // Extract and display results
    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)

    print("\nDisplacements:")
    if let w0 = assembly.getDisplacement(atDOF: node0DOFs[0]),
       let gamma0 = assembly.getDisplacement(atDOF: node0DOFs[1]),
       let w1 = assembly.getDisplacement(atDOF: node1DOFs[0]),
       let gamma1 = assembly.getDisplacement(atDOF: node1DOFs[1]) {

        print("\n  Node 0 (z=0mm, fixed end):")
        print("    w (transverse):  \(String(format: "%.6f", w0)) mm")
        print("    γ (rotation):    \(String(format: "%.6e", gamma0)) rad")

        print("\n  Node 1 (z=\(length1 + length2)mm, free end):")
        print("    w (transverse):  \(String(format: "%.6f", w1)) mm")
        print("    γ (rotation):    \(String(format: "%.6e", gamma1)) rad")

        // Theoretical maximum deflection for cantilever beam with end load:
        // δ_max = FL³/(3EI)
        let L = length1 + length2
        let F = abs(endForce)
        let I = Double.pi * pow(diameter, 4) / 64.0
        let theoreticalDeflection = F * pow(L, 3) / (3.0 * E * I)

        print("\n  Analytical Solution (Euler-Bernoulli):")
        print("    End deflection: \(String(format: "%.6f", theoreticalDeflection)) mm")
        print("    FEA end deflection: \(String(format: "%.6f", abs(w1))) mm")

        let error = abs(abs(w1) - theoreticalDeflection) / theoreticalDeflection * 100.0
        print("    Error: \(String(format: "%.2f", error))%")
    }

    print("\n" + "=" * 60)
}

// Helper to repeat string (like Python's "*" operator)
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run the example
runShaftExample()
