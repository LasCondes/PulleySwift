import Foundation

/// Represents a node in the finite element mesh
/// Converted from C++ cNode in cNode.h
public final class Node {
    /// Node displacements (degrees of freedom)
    public var displacements: [Double]

    /// Global indices for each displacement component
    private var indices: [Int]

    /// Number of displacement components
    public let numberOfDisplacements: Int

    public init(numberOfDisplacements: Int) {
        self.numberOfDisplacements = numberOfDisplacements
        self.displacements = Array(repeating: 0.0, count: numberOfDisplacements)
        self.indices = Array(repeating: -1, count: numberOfDisplacements)
    }

    /// Reset displacement indices (used during assembly)
    public func resetIndices() {
        indices = Array(repeating: -1, count: numberOfDisplacements)
    }

    /// Get index for displacement component
    public func index(at component: Int) -> Int {
        guard component < numberOfDisplacements else { return -1 }
        return indices[component]
    }

    /// Set index for displacement component
    public func setIndex(_ index: Int, at component: Int) {
        guard component < numberOfDisplacements else { return }
        indices[component] = index
    }
}
