import XCTest
@testable import PulleyStandards
@testable import PulleyCore

final class AS1403StandardTests: XCTestCase {
    func testSteppedShaftFactorDelta() {
        let delta = AS1403Standard.steppedShaftFactorDelta(D: 100.0, D1: 80.0)
        XCTAssertEqual(delta, 0.2, accuracy: 0.001)
    }

    func testSteppedShaftFactorK() {
        // Test with values in table range
        let K = AS1403Standard.steppedShaftFactorK(Z: 0.1, Fu: 500.0)
        XCTAssertGreaterThan(K, 1.0)
        XCTAssertLessThan(K, 3.5)
    }

    func testIsInsideValidRange() {
        XCTAssertTrue(AS1403Standard.isInside(Fu: 500.0))
        XCTAssertTrue(AS1403Standard.isInside(Fu: 350.0))
        XCTAssertTrue(AS1403Standard.isInside(Fu: 900.0))
        XCTAssertFalse(AS1403Standard.isInside(Fu: 300.0))
        XCTAssertFalse(AS1403Standard.isInside(Fu: 1000.0))
    }

    func testCombinedStress() {
        // Test stress combination when points are close
        let K_combined = AS1403Standard.combinedStress(
            distance: 50.0,
            diameter: 100.0,
            K: 2.0,
            Kcloseby: 2.5
        )

        // Should be between K and K + (Kcloseby - 1)
        XCTAssertGreaterThan(K_combined, 2.0)
        XCTAssertLessThan(K_combined, 3.0)

        // Test when points are far apart
        let K_far = AS1403Standard.combinedStress(
            distance: 150.0,
            diameter: 100.0,
            K: 2.0,
            Kcloseby: 2.5
        )

        // Should equal K when far apart
        XCTAssertEqual(K_far, 2.0)
    }

    func testSafetyFactorCalculation() {
        let standard = AS1403Standard()

        let material = Material(
            itemNumber: "S355",
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            yieldStrength: 355.0,
            enduranceLimit: 200.0,
            ultimateStrength: 490.0,
            density: 7850.0,
            baseStress: 180.0
        )

        let safetyFactor = standard.calculateSafetyFactor(
            hasTorqueReversal: false,
            isLiveShaft: true,
            diameter: 100.0,
            moment: 50000.0,
            torque: 30000.0,
            material: material,
            stressConcentrationFactor: 1.5
        )

        XCTAssertGreaterThan(safetyFactor, 0)
        XCTAssertLessThan(safetyFactor, 1000)  // Reasonable upper bound
    }
}
