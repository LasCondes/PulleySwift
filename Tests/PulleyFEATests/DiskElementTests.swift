import XCTest
@testable import PulleyFEA
@testable import PulleyCore

final class DiskElementTests: XCTestCase {
    func testDiskElementInitialization() {
        let element = DiskElement(
            innerRadius: 100.0,
            outerRadius: 500.0,
            thicknessBegin: 20.0,
            thicknessEnd: 15.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: false,
            mode: 1
        )

        XCTAssertEqual(element.elementType, .disk)
        XCTAssertEqual(element.nodes.count, 2)
        XCTAssertEqual(element.numberOfDisplacements(), 4)
    }

    func testLinearThicknessInterpolation() {
        let element = DiskElement(
            innerRadius: 100.0,
            outerRadius: 500.0,
            thicknessBegin: 20.0,
            thicknessEnd: 10.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: false,
            mode: 1
        )

        // Test thickness at inner radius
        let t0 = element.thickness(at: 100.0)
        XCTAssertEqual(t0, 20.0, accuracy: 0.01)

        // Test thickness at outer radius
        let tL = element.thickness(at: 500.0)
        XCTAssertEqual(tL, 10.0, accuracy: 0.01)

        // Test thickness at midpoint
        let tMid = element.thickness(at: 300.0)
        XCTAssertEqual(tMid, 15.0, accuracy: 0.01)
    }

    func testDiskElementWithGravity() {
        let element = DiskElement(
            innerRadius: 100.0,
            outerRadius: 500.0,
            thicknessBegin: 20.0,
            thicknessEnd: 15.0,
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            useNumericalIntegration: false,
            mode: 1
        )

        XCTAssertFalse(element.hasAppliedLoad())

        element.addGravity(9.81, density: 7850.0)

        XCTAssertTrue(element.hasAppliedLoad())
    }
}
