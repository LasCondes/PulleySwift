import Foundation
import AxiSymFEA
import PulleyCore

/// Example: cantilever shaft with an end load
/// A shaft of length 1000mm and diameter 50mm, fixed at z = 0, with a transverse force of
/// 1000N at the free end.
///
/// Geometry:
/// |=============== 1000mm ===============|
/// Fixed                                   ↓ 1000N
///
/// A transverse load bends the shaft, which AxiSymFEA analyses in Fourier mode 1 (mode 0 carries
/// axial force and torque). A shaft node's degrees of freedom are radial, rotation, axial and
/// torsion; at mode 1 only radial and rotation take part.

func runShaftExample() {
    print("=" * 60)
    print("SHAFT FEA EXAMPLE: Cantilever Beam with End Load")
    print("=" * 60)

    // Material properties (Steel)
    let E = 210000.0  // Young's modulus (MPa)
    let nu = 0.3      // Poisson's ratio
    let diameter = 50.0  // mm
    let length = 1000.0  // mm

    print("\nModel Parameters:")
    print("  Material: Steel")
    print("  Young's Modulus: \(E) MPa")
    print("  Poisson's Ratio: \(nu)")
    print("  Shaft Diameter: \(diameter) mm")
    print("  Total Length: \(length) mm")
    print("  Elements: 1 (Timoshenko beam)")

    let steel = Material(youngsModulus: E, poissonsRatio: nu)
    let fixedEnd = Node.shaft(id: 0, z: 0.0)
    let freeEnd = Node.shaft(id: 1, z: length)
    let mode = 1  // bending
    let element = ShaftElement(node1: fixedEnd, node2: freeEnd, diameter: diameter,
                               material: steel, mode: mode, model: .timoshenko())
    let model = AxisymmetricModel(mode: mode, elements: [element])
    print("  Nodes: \(model.nodeCount), Fourier mode: \(mode)")

    // Fixed end: no deflection and no rotation.
    print("\nApplying Boundary Conditions:")
    let supports: [BoundaryCondition] = [.fixed(.radial, at: fixedEnd), .fixed(.meridionalRotation, at: fixedEnd)]
    print("  Node 0: Fixed (cantilever support)")

    // Transverse load at the free end. HarmonicNodalLoad takes the physical force.
    let endForce = -1000.0  // N (downward)
    let loads = [HarmonicNodalLoad(endForce, on: .radial, at: freeEnd)]
    print("\nApplying Loads:")
    print("  Node 1 (free end): Transverse force = \(endForce) N")

    print("\nSolving...")
    let solution: HarmonicSolution
    do {
        solution = try HarmonicProblem(model: model, boundaryConditions: supports, nodalLoads: loads).solve(output: .none)
        print("✓ Solution converged")
    } catch {
        print("✗ Solution failed: \(error.localizedDescription)")
        return
    }

    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)

    print("\nDisplacements:")
    do {
        let w0 = try solution.displacement(.radial, at: fixedEnd)
        let gamma0 = try solution.displacement(.meridionalRotation, at: fixedEnd)
        let w1 = try solution.displacement(.radial, at: freeEnd)
        let gamma1 = try solution.displacement(.meridionalRotation, at: freeEnd)

        print("\n  Node 0 (z=0mm, fixed end):")
        print("    w (transverse):  \(String(format: "%.6f", w0)) mm")
        print("    γ (rotation):    \(String(format: "%.6e", gamma0)) rad")

        print("\n  Node 1 (z=\(length)mm, free end):")
        print("    w (transverse):  \(String(format: "%.6f", w1)) mm")
        print("    γ (rotation):    \(String(format: "%.6e", gamma1)) rad")

        // Theoretical maximum deflection for cantilever beam with end load:
        // δ_max = FL³/(3EI)
        let F = abs(endForce)
        let I = Double.pi * pow(diameter, 4) / 64.0
        let theoreticalDeflection = F * pow(length, 3) / (3.0 * E * I)

        print("\n  Analytical Solution (Euler-Bernoulli):")
        print("    End deflection: \(String(format: "%.6f", theoreticalDeflection)) mm")
        print("    FEA end deflection: \(String(format: "%.6f", abs(w1))) mm")

        let error = abs(abs(w1) - theoreticalDeflection) / theoreticalDeflection * 100.0
        print("    Error: \(String(format: "%.2f", error))%")
    } catch {
        print("  Couldn't read the displacements: \(error.localizedDescription)")
    }

    print("\n" + "=" * 60)
}

// Helper to repeat string (like Python's "*" operator)
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Main entry point
@main
struct ShaftExampleMain {
    static func main() {
        runShaftExample()
    }
}
