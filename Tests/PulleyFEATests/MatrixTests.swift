import XCTest
@testable import PulleyFEA

final class MatrixTests: XCTestCase {
    func testMatrixInitialization() {
        let matrix = Matrix(rows: 3, columns: 3, repeating: 0.0)

        XCTAssertEqual(matrix.rows, 3)
        XCTAssertEqual(matrix.columns, 3)

        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(matrix[i, j], 0.0)
            }
        }
    }

    func testMatrixZero() {
        let matrix = Matrix.zero(rows: 2, columns: 3)

        XCTAssertEqual(matrix.rows, 2)
        XCTAssertEqual(matrix.columns, 3)

        for i in 0..<2 {
            for j in 0..<3 {
                XCTAssertEqual(matrix[i, j], 0.0)
            }
        }
    }

    func testMatrixIdentity() {
        let identity = Matrix.identity(size: 3)

        XCTAssertEqual(identity.rows, 3)
        XCTAssertEqual(identity.columns, 3)

        for i in 0..<3 {
            for j in 0..<3 {
                if i == j {
                    XCTAssertEqual(identity[i, j], 1.0)
                } else {
                    XCTAssertEqual(identity[i, j], 0.0)
                }
            }
        }
    }

    func testMatrixSubscript() {
        var matrix = Matrix.zero(rows: 2, columns: 2)

        matrix[0, 0] = 1.0
        matrix[0, 1] = 2.0
        matrix[1, 0] = 3.0
        matrix[1, 1] = 4.0

        XCTAssertEqual(matrix[0, 0], 1.0)
        XCTAssertEqual(matrix[0, 1], 2.0)
        XCTAssertEqual(matrix[1, 0], 3.0)
        XCTAssertEqual(matrix[1, 1], 4.0)
    }

    func testMatrixMultiplication() {
        var A = Matrix.zero(rows: 2, columns: 2)
        A[0, 0] = 1.0
        A[0, 1] = 2.0
        A[1, 0] = 3.0
        A[1, 1] = 4.0

        var B = Matrix.zero(rows: 2, columns: 2)
        B[0, 0] = 5.0
        B[0, 1] = 6.0
        B[1, 0] = 7.0
        B[1, 1] = 8.0

        let C = A * B

        // C = A * B = [[19, 22], [43, 50]]
        XCTAssertEqual(C[0, 0], 19.0, accuracy: 1e-10)
        XCTAssertEqual(C[0, 1], 22.0, accuracy: 1e-10)
        XCTAssertEqual(C[1, 0], 43.0, accuracy: 1e-10)
        XCTAssertEqual(C[1, 1], 50.0, accuracy: 1e-10)
    }

    func testVectorInitialization() {
        let vector = Vector(size: 3, repeating: 0.0)

        XCTAssertEqual(vector.size, 3)

        for i in 0..<3 {
            XCTAssertEqual(vector[i], 0.0)
        }
    }

    func testVectorZero() {
        let vector = Vector.zero(size: 4)

        XCTAssertEqual(vector.size, 4)

        for i in 0..<4 {
            XCTAssertEqual(vector[i], 0.0)
        }
    }

    func testVectorSubscript() {
        var vector = Vector.zero(size: 3)

        vector[0] = 1.0
        vector[1] = 2.0
        vector[2] = 3.0

        XCTAssertEqual(vector[0], 1.0)
        XCTAssertEqual(vector[1], 2.0)
        XCTAssertEqual(vector[2], 3.0)
    }

    func testVectorAddition() {
        var v1 = Vector.zero(size: 3)
        v1[0] = 1.0
        v1[1] = 2.0
        v1[2] = 3.0

        var v2 = Vector.zero(size: 3)
        v2[0] = 4.0
        v2[1] = 5.0
        v2[2] = 6.0

        let v3 = v1 + v2

        XCTAssertEqual(v3[0], 5.0)
        XCTAssertEqual(v3[1], 7.0)
        XCTAssertEqual(v3[2], 9.0)
    }

    func testVectorScalarMultiplication() {
        var v = Vector.zero(size: 3)
        v[0] = 1.0
        v[1] = 2.0
        v[2] = 3.0

        let v2 = 2.0 * v

        XCTAssertEqual(v2[0], 2.0)
        XCTAssertEqual(v2[1], 4.0)
        XCTAssertEqual(v2[2], 6.0)
    }
}
