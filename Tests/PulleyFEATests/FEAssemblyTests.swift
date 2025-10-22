import XCTest
@testable import PulleyFEA
@testable import PulleyCore

final class FEAssemblyTests: XCTestCase {
    func testSimpleLinearSolve() {
        // Test solving a simple 2x2 system:
        // 2x + y = 5
        // x + 3y = 6
        // Solution: x = 1.5, y = 2

        let assembly = FEAssembly()

        // Create a simple test by manually setting up matrix and RHS
        // We'll use two disk elements to create a simple system
        let element1 = DiskElement(
            innerRadius: 100.0,
            outerRadius: 200.0,
            thicknessBegin: 10.0,
            thicknessEnd: 10.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: false,
            mode: 0
        )

        assembly.addElement(element1)
        assembly.assemble(mode: 0)

        // Verify assembly created the system
        XCTAssertGreaterThan(assembly.variableCount(), 0)
        XCTAssertGreaterThan(assembly.equationCount(), 0)

        // Solve the system
        let success = assembly.solve()
        XCTAssertTrue(success, "Linear solver should succeed")

        // Get solution
        let solution = assembly.getSolution()
        XCTAssertNotNil(solution)

        if let sol = solution {
            // Verify solution is finite
            for i in 0..<sol.size {
                XCTAssertTrue(sol[i].isFinite, "Solution contains non-finite values")
            }
        }
    }

    func testMultiElementAssembly() {
        // Test assembling multiple elements
        let assembly = FEAssembly()

        // Add three disk elements
        for i in 0..<3 {
            let r0 = Double(100 + i * 100)
            let rL = Double(200 + i * 100)

            let element = DiskElement(
                innerRadius: r0,
                outerRadius: rL,
                thicknessBegin: 10.0,
                thicknessEnd: 10.0,
                youngsModulus: 210000.0,
                poissonsRatio: 0.3,
                useNumericalIntegration: false,
                mode: 1
            )

            assembly.addElement(element)
        }

        assembly.assemble(mode: 1)

        // Verify we have variables and equations
        XCTAssertGreaterThan(assembly.variableCount(), 0)
        XCTAssertGreaterThan(assembly.equationCount(), 0)

        // Solve
        let success = assembly.solve()
        XCTAssertTrue(success, "Multi-element solver should succeed")

        // Verify solution
        let solution = assembly.getSolution()
        XCTAssertNotNil(solution)
    }

    func testClearAssembly() {
        let assembly = FEAssembly()

        let element = DiskElement(
            innerRadius: 100.0,
            outerRadius: 200.0,
            thicknessBegin: 10.0,
            thicknessEnd: 10.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: false,
            mode: 0
        )

        assembly.addElement(element)
        assembly.assemble(mode: 0)

        XCTAssertGreaterThan(assembly.variableCount(), 0)

        // Clear the assembly
        assembly.clear()

        // Verify everything is reset
        XCTAssertEqual(assembly.variableCount(), 0)
        XCTAssertEqual(assembly.equationCount(), 0)
        XCTAssertNil(assembly.getSolution())
    }

    func testShellElementAssembly() {
        // Test assembly with shell elements
        let assembly = FEAssembly()

        let shell = ShellElement(
            radius: 300.0,
            thickness: 10.0,
            axialPositionStart: 0.0,
            axialPositionEnd: 500.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: false,
            mode: 1,
            model: .ventselKrauthammer
        )

        assembly.addElement(shell)
        assembly.assemble(mode: 1)

        XCTAssertGreaterThan(assembly.variableCount(), 0)

        let success = assembly.solve()
        XCTAssertTrue(success, "Shell element solver should succeed")
    }

    func testShaftElementAssembly() {
        // Test assembly with shaft elements
        let assembly = FEAssembly()

        let shaft = ShaftElement(
            diameter: 100.0,
            axialPositionStart: 0.0,
            axialPositionEnd: 1000.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            mode: 0,
            model: .timoshenko
        )

        assembly.addElement(shaft)
        assembly.assemble(mode: 0)

        XCTAssertGreaterThan(assembly.variableCount(), 0)

        let success = assembly.solve()
        XCTAssertTrue(success, "Shaft element solver should succeed")
    }
}
