import Foundation
import Accelerate

/// Simple matrix type using Swift arrays
/// Will be replaced with more efficient implementation using Accelerate framework
public struct Matrix {
    public let rows: Int
    public let columns: Int
    private var data: [Double]

    public init(rows: Int, columns: Int, repeating value: Double = 0.0) {
        self.rows = rows
        self.columns = columns
        self.data = Array(repeating: value, count: rows * columns)
    }

    public init(rows: Int, columns: Int, data: [Double]) {
        precondition(data.count == rows * columns, "Data count must match rows * columns")
        self.rows = rows
        self.columns = columns
        self.data = data
    }

    public subscript(row: Int, column: Int) -> Double {
        get {
            precondition(row >= 0 && row < rows && column >= 0 && column < columns, "Index out of bounds")
            return data[row * columns + column]
        }
        set {
            precondition(row >= 0 && row < rows && column >= 0 && column < columns, "Index out of bounds")
            data[row * columns + column] = newValue
        }
    }

    /// Create zero matrix
    public static func zero(rows: Int, columns: Int) -> Matrix {
        return Matrix(rows: rows, columns: columns, repeating: 0.0)
    }

    /// Create identity matrix
    public static func identity(size: Int) -> Matrix {
        var matrix = Matrix.zero(rows: size, columns: size)
        for i in 0..<size {
            matrix[i, i] = 1.0
        }
        return matrix
    }

    /// Matrix multiplication
    public static func * (lhs: Matrix, rhs: Matrix) -> Matrix {
        precondition(lhs.columns == rhs.rows, "Matrix dimensions incompatible for multiplication")

        var result = Matrix.zero(rows: lhs.rows, columns: rhs.columns)

        // Use BLAS for matrix multiplication (DGEMM)
        cblas_dgemm(
            CblasRowMajor,
            CblasNoTrans,
            CblasNoTrans,
            Int32(lhs.rows),
            Int32(rhs.columns),
            Int32(lhs.columns),
            1.0,
            lhs.data,
            Int32(lhs.columns),
            rhs.data,
            Int32(rhs.columns),
            0.0,
            &result.data,
            Int32(result.columns)
        )

        return result
    }

    /// Access raw data
    public var flattenedData: [Double] {
        return data
    }
}

/// Vector type (column vector)
public struct Vector {
    public let size: Int
    private var data: [Double]

    public init(size: Int, repeating value: Double = 0.0) {
        self.size = size
        self.data = Array(repeating: value, count: size)
    }

    public init(data: [Double]) {
        self.size = data.count
        self.data = data
    }

    public subscript(index: Int) -> Double {
        get {
            precondition(index >= 0 && index < size, "Index out of bounds")
            return data[index]
        }
        set {
            precondition(index >= 0 && index < size, "Index out of bounds")
            data[index] = newValue
        }
    }

    /// Create zero vector
    public static func zero(size: Int) -> Vector {
        return Vector(size: size, repeating: 0.0)
    }

    /// Vector addition
    public static func + (lhs: Vector, rhs: Vector) -> Vector {
        precondition(lhs.size == rhs.size, "Vector sizes must match")
        var result = Vector.zero(size: lhs.size)
        for i in 0..<lhs.size {
            result[i] = lhs[i] + rhs[i]
        }
        return result
    }

    /// Scalar multiplication
    public static func * (scalar: Double, vector: Vector) -> Vector {
        var result = Vector.zero(size: vector.size)
        for i in 0..<vector.size {
            result[i] = scalar * vector[i]
        }
        return result
    }

    /// Access raw data
    public var flattenedData: [Double] {
        return data
    }
}
