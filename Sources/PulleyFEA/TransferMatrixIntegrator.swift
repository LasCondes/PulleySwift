import Foundation

/// Transfer matrix integration using exponential scaling
/// Based on the method from Appendix D of the pulley FEA documentation
public final class TransferMatrixIntegrator {

    /// Integrate transfer matrix from start to end position
    /// Uses logarithmic spacing and matrix exponential approximation
    /// - Parameters:
    ///   - Hm: ODE matrix function H(z) that varies along element
    ///   - load: Load vector function L(z)
    ///   - start: Starting position
    ///   - end: Ending position
    ///   - hasLoad: Whether element has applied loads
    /// - Returns: Tuple of (transfer matrix T, load vector P)
    public static func integrate(
        Hm: (Double) -> Matrix,
        load: (Double) -> Vector,
        start: Double,
        end: Double,
        hasLoad: Bool = false
    ) -> (transferMatrix: Matrix, loadVector: Vector) {

        // Number of integration points (more if loads present)
        let nPoints = hasLoad ? 10 : 3

        // Scaling parameter M (controls accuracy)
        let M = 12
        let m = Int(pow(2.0, Double(M)))

        // Logarithmic spacing
        let dlnz = (log(end) - log(start)) / Double(nPoints - 1)
        let tau = dlnz / Double(m)

        // Get matrix size
        let H_sample = Hm(start)
        let size = H_sample.rows

        // Initialize transfer matrix as identity
        var Tm = Matrix.identity(size: size)

        // Initialize load vector
        var P = Vector.zero(size: size)

        // Integrate over logarithmically-spaced points
        for i in 0..<nPoints {
            let lnz = log(start) + Double(i) * dlnz
            let z = exp(lnz)

            // Get H matrix at this position
            let H = Hm(z)

            // Compute Htau = H * tau
            let Htau_data = H.flattenedData.map { $0 * tau }
            let Htau = Matrix(rows: size, columns: size, data: Htau_data)

            // Matrix exponential approximation using Taylor series
            // exp(Htau) ≈ I + Htau + Htau²/2! + Htau³/3! + Htau⁴/4!
            var Tm0 = Htau

            // Add Htau²/2
            let Htau2 = Htau * Htau
            Tm0 = addMatrices(Tm0, scaleMatrix(Htau2, 0.5))

            // Add Htau³/6
            let Htau3 = Htau2 * Htau
            Tm0 = addMatrices(Tm0, scaleMatrix(Htau3, 1.0/6.0))

            // Add Htau⁴/24
            let Htau4 = Htau3 * Htau
            Tm0 = addMatrices(Tm0, scaleMatrix(Htau4, 1.0/24.0))

            // Binary scaling: repeatedly square to get exp(2^M * tau)
            for _ in 0..<M {
                // Tm0 = 2*Tm0 + Tm0*Tm0  (Equation 15)
                Tm0 = addMatrices(scaleMatrix(Tm0, 2.0), Tm0 * Tm0)
            }

            // Add identity
            Tm0 = addMatrices(Matrix.identity(size: size), Tm0)

            // Accumulate: Tm = Tm0 * Tm
            Tm = Tm0 * Tm

            // Integrate load vector if present
            if hasLoad {
                let L = load(z)
                // P = Tm0 * P + integrated_load
                // Simplified: P = P + L * dlnz * z
                let scaled_load = L.flattenedData.map { $0 * dlnz * z }
                P = addVectors(P, Vector(data: scaled_load))
            }
        }

        return (transferMatrix: Tm, loadVector: P)
    }

    /// Integrate transfer matrix for constant H matrix (analytical case)
    /// - Parameters:
    ///   - H: Constant ODE matrix
    ///   - length: Element length
    /// - Returns: Transfer matrix
    public static func integrateConstant(
        H: Matrix,
        length: Double
    ) -> Matrix {
        let size = H.rows

        // For constant H, T = exp(H * L)
        // Use same scaling approach
        let M = 12
        let m = Int(pow(2.0, Double(M)))
        let tau = length / Double(m)

        // Htau = H * tau
        let Htau_data = H.flattenedData.map { $0 * tau }
        var Tm = Matrix(rows: size, columns: size, data: Htau_data)

        // Taylor series
        let Htau = Tm
        let Htau2 = Htau * Htau
        Tm = addMatrices(Tm, scaleMatrix(Htau2, 0.5))

        let Htau3 = Htau2 * Htau
        Tm = addMatrices(Tm, scaleMatrix(Htau3, 1.0/6.0))

        let Htau4 = Htau3 * Htau
        Tm = addMatrices(Tm, scaleMatrix(Htau4, 1.0/24.0))

        // Binary scaling
        for _ in 0..<M {
            Tm = addMatrices(scaleMatrix(Tm, 2.0), Tm * Tm)
        }

        // Add identity
        Tm = addMatrices(Matrix.identity(size: size), Tm)

        return Tm
    }

    // MARK: - Helper Methods

    private static func addMatrices(_ A: Matrix, _ B: Matrix) -> Matrix {
        precondition(A.rows == B.rows && A.columns == B.columns)

        var result = Matrix.zero(rows: A.rows, columns: A.columns)
        for i in 0..<A.rows {
            for j in 0..<A.columns {
                result[i, j] = A[i, j] + B[i, j]
            }
        }
        return result
    }

    private static func scaleMatrix(_ A: Matrix, _ scalar: Double) -> Matrix {
        var result = Matrix.zero(rows: A.rows, columns: A.columns)
        for i in 0..<A.rows {
            for j in 0..<A.columns {
                result[i, j] = A[i, j] * scalar
            }
        }
        return result
    }

    private static func addVectors(_ a: Vector, _ b: Vector) -> Vector {
        precondition(a.size == b.size)

        var result = Vector.zero(size: a.size)
        for i in 0..<a.size {
            result[i] = a[i] + b[i]
        }
        return result
    }
}
