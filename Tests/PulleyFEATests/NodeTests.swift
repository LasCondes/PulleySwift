import XCTest
@testable import PulleyFEA

final class NodeTests: XCTestCase {
    func testNodeInitialization() {
        let node = Node(numberOfDisplacements: 4)

        XCTAssertEqual(node.numberOfDisplacements, 4)
        XCTAssertEqual(node.displacements.count, 4)

        // Check initial displacements are zero
        for i in 0..<4 {
            XCTAssertEqual(node.displacements[i], 0.0)
        }
    }

    func testNodeIndexAssignment() {
        let node = Node(numberOfDisplacements: 4)

        // Initially all indices should be -1
        for i in 0..<4 {
            XCTAssertEqual(node.index(at: i), -1)
        }

        // Set indices
        node.setIndex(0, at: 0)
        node.setIndex(1, at: 1)
        node.setIndex(2, at: 2)
        node.setIndex(3, at: 3)

        // Verify indices
        XCTAssertEqual(node.index(at: 0), 0)
        XCTAssertEqual(node.index(at: 1), 1)
        XCTAssertEqual(node.index(at: 2), 2)
        XCTAssertEqual(node.index(at: 3), 3)
    }

    func testNodeResetIndices() {
        let node = Node(numberOfDisplacements: 4)

        // Set indices
        for i in 0..<4 {
            node.setIndex(i, at: i)
        }

        // Reset indices
        node.resetIndices()

        // Verify all indices are -1
        for i in 0..<4 {
            XCTAssertEqual(node.index(at: i), -1)
        }
    }
}
