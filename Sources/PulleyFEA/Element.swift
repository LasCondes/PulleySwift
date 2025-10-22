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

    /// Compute element stiffness matrix (for direct stiffness method)
    /// - Returns: Element stiffness matrix (nil if element uses transfer matrix method)
    func computeElementStiffness() -> Matrix?
}

// Extension providing default implementations
extension Element {
    public func numberOfDisplacements() -> Int {
        return 4  // Default: u, v, w, theta
    }

    public func computeElementStiffness() -> Matrix? {
        return nil  // Default: use transfer matrix method
    }
}
