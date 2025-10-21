import Foundation

/// Element type classification
public enum ElementType {
    case beam
    case barBeam
    case disk
    case shell
}

/// Base protocol for finite elements
/// Converted from C++ cElement in cElement.h
public protocol Element: AnyObject {
    var elementType: ElementType { get }
    var nodes: [Node] { get }

    /// Number of displacement components per node
    func numberOfDisplacements() -> Int

    /// Compute transfer matrix and load vector
    /// - Returns: Tuple of (transferMatrix, loadVector)
    func computeTransferMatrixAndLoad() -> (matrix: [[Double]], load: [Double])
}

// Extension providing default implementations
extension Element {
    public func numberOfDisplacements() -> Int {
        return 4  // Default: u, v, w, theta
    }
}
