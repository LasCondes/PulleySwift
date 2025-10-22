import XCTest
@testable import PulleyFEA

final class TransferMatrixTests: XCTestCase {
    func testTransferMatrixIntegrationConstant() {
        // Test with constant H matrix (analytical case)
        // For constant H, exp(H*L) should equal Identity + H*L for small L

        let size = 4
        var H = Matrix.zero(rows: size, columns: size)

        // Simple diagonal matrix
        H[0, 0] = 0.1
        H[1, 1] = 0.2
        H[2, 2] = 0.3
        H[3, 3] = 0.4

        let length = 0.1
        let T = TransferMatrixIntegrator.integrateConstant(H: H, length: length)

        // For small values, exp(H*L) ≈ I + H*L
        // Check diagonal elements
        XCTAssertEqual(T[0, 0], 1.0 + 0.1 * 0.1, accuracy: 0.01)
        XCTAssertEqual(T[1, 1], 1.0 + 0.2 * 0.1, accuracy: 0.01)
        XCTAssertEqual(T[2, 2], 1.0 + 0.3 * 0.1, accuracy: 0.01)
        XCTAssertEqual(T[3, 3], 1.0 + 0.4 * 0.1, accuracy: 0.01)

        // Off-diagonal should be near zero
        XCTAssertEqual(T[0, 1], 0.0, accuracy: 0.001)
        XCTAssertEqual(T[1, 0], 0.0, accuracy: 0.001)
    }

    func testTransferMatrixIdentity() {
        // With H = 0, transfer matrix should be identity
        let size = 4
        let H = Matrix.zero(rows: size, columns: size)
        let length = 1.0

        let T = TransferMatrixIntegrator.integrateConstant(H: H, length: length)

        // Should be identity matrix
        for i in 0..<size {
            for j in 0..<size {
                if i == j {
                    XCTAssertEqual(T[i, j], 1.0, accuracy: 0.0001)
                } else {
                    XCTAssertEqual(T[i, j], 0.0, accuracy: 0.0001)
                }
            }
        }
    }

    func testDiskElementTransferMatrix() {
        // Test disk element transfer matrix computation
        let element = DiskElement(
            innerRadius: 100.0,
            outerRadius: 500.0,
            thicknessBegin: 20.0,
            thicknessEnd: 15.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: true,
            mode: 1
        )

        let (matrix, load) = element.computeTransferMatrixAndLoad()

        // Transfer matrix should be 8x8
        XCTAssertEqual(matrix.count, 8)
        XCTAssertEqual(matrix[0].count, 8)

        // Load vector should be size 8
        XCTAssertEqual(load.count, 8)

        // Transfer matrix should be finite
        for row in matrix {
            for value in row {
                XCTAssertTrue(value.isFinite, "Transfer matrix contains non-finite values")
            }
        }

        // Diagonal elements should be non-zero (typically > 1 for transfer matrix)
        for i in 0..<8 {
            XCTAssertNotEqual(matrix[i][i], 0.0, accuracy: 0.0001)
        }
    }

    func testDiskElementWithGravityTransferMatrix() {
        // Test disk element with gravity loading
        let element = DiskElement(
            innerRadius: 100.0,
            outerRadius: 500.0,
            thicknessBegin: 20.0,
            thicknessEnd: 15.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: true,
            mode: 1
        )

        // Add gravity
        element.addGravity(9.81, density: 7850.0)

        let (matrix, load) = element.computeTransferMatrixAndLoad()

        // Load vector should have non-zero components when gravity is applied
        var hasNonZeroLoad = false
        for value in load {
            if abs(value) > 1e-6 {
                hasNonZeroLoad = true
                break
            }
        }

        XCTAssertTrue(hasNonZeroLoad, "Load vector should be non-zero with gravity")
    }

    func testShellElementTransferMatrix() {
        // Test shell element transfer matrix computation
        let element = ShellElement(
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

        let (matrix, load) = element.computeTransferMatrixAndLoad()

        // Transfer matrix should be 8x8
        XCTAssertEqual(matrix.count, 8)
        XCTAssertEqual(matrix[0].count, 8)

        // Load vector should be size 8
        XCTAssertEqual(load.count, 8)

        // Transfer matrix should be finite
        for row in matrix {
            for value in row {
                XCTAssertTrue(value.isFinite, "Transfer matrix contains non-finite values")
            }
        }

        // Diagonal elements should be non-zero
        for i in 0..<8 {
            XCTAssertNotEqual(matrix[i][i], 0.0, accuracy: 0.0001)
        }
    }

    func testShaftElementTransferMatrix() {
        // Test shaft element transfer matrix computation
        let element = ShaftElement(
            diameter: 100.0,
            axialPositionStart: 0.0,
            axialPositionEnd: 1000.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            mode: 1,
            model: .timoshenko
        )

        let (matrix, load) = element.computeTransferMatrixAndLoad()

        // Transfer matrix should be 8x8
        XCTAssertEqual(matrix.count, 8)
        XCTAssertEqual(matrix[0].count, 8)

        // Load vector should be size 8
        XCTAssertEqual(load.count, 8)

        // Transfer matrix should be finite
        for row in matrix {
            for value in row {
                XCTAssertTrue(value.isFinite, "Transfer matrix contains non-finite values")
            }
        }

        // Diagonal elements should be non-zero
        for i in 0..<8 {
            XCTAssertNotEqual(matrix[i][i], 0.0, accuracy: 0.0001)
        }
    }

    func testShaftElementEulerBernoulli() {
        // Test shaft element with Euler-Bernoulli model
        let element = ShaftElement(
            diameter: 50.0,
            axialPositionStart: 0.0,
            axialPositionEnd: 500.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            mode: 0,
            model: .eulerBernoulli
        )

        let (matrix, load) = element.computeTransferMatrixAndLoad()

        // Transfer matrix should be finite and valid
        XCTAssertEqual(matrix.count, 8)
        for row in matrix {
            for value in row {
                XCTAssertTrue(value.isFinite, "Transfer matrix contains non-finite values")
            }
        }
    }
}
