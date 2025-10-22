import XCTest
@testable import PulleyStandards
@testable import PulleyCore

final class ANSIStandardTests: XCTestCase {
    func testSafetyFactorCalculation() {
        let standard = ANSIStandard()

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
            isLiveShaft: true,
            diameter: 100.0,
            moment: 50000.0,
            torque: 30000.0,
            material: material,
            fatigueStressConcentrationFactor: 1.0
        )

        XCTAssertGreaterThan(safetyFactor, 0)
        XCTAssertLessThan(safetyFactor, 1000)  // Reasonable range
    }

    func testMinimumDiameterCalculation() {
        let standard = ANSIStandard()

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

        let minDiameter = standard.minimumDiameter(
            isLiveShaft: true,
            currentDiameter: 100.0,
            moment: 50000.0,
            torque: 30000.0,
            material: material,
            fatigueStressConcentrationFactor: 1.0,
            requiredSafetyFactor: 2.0
        )

        XCTAssertGreaterThan(minDiameter, 0)
        XCTAssertLessThan(minDiameter, 500.0)  // Reasonable range
    }

    func testZeroLoadingGivesInfiniteSafetyFactor() {
        let standard = ANSIStandard()

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
            isLiveShaft: true,
            diameter: 100.0,
            moment: 0.0,
            torque: 0.0,
            material: material
        )

        XCTAssertEqual(safetyFactor, Double.greatestFiniteMagnitude)
    }
}
