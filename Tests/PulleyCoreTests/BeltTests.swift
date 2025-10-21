import XCTest
@testable import PulleyCore

final class BeltTests: XCTestCase {
    func testBeltInitialization() {
        let belt = Belt(
            width: 1200.0,
            wrapAngle: 3.14159,
            thickness: 10.0,
            speed: 5.0,
            approachAngle: 0.0,
            laggingThickness: 12.0,
            torqueReversal: false,
            rotationClockwise: true
        )

        XCTAssertEqual(belt.width, 1200.0)
        XCTAssertEqual(belt.wrapAngle, 3.14159, accuracy: 0.0001)
        XCTAssertEqual(belt.thickness, 10.0)
        XCTAssertEqual(belt.speed, 5.0)
        XCTAssertFalse(belt.torqueReversal)
        XCTAssertTrue(belt.rotationClockwise)
    }

    func testBeltJSONEncoding() throws {
        let belt = Belt(
            width: 1200.0,
            wrapAngle: 3.14159,
            thickness: 10.0,
            speed: 5.0,
            approachAngle: 0.0,
            laggingThickness: 12.0,
            torqueReversal: false,
            rotationClockwise: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(belt)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Belt.self, from: data)

        XCTAssertEqual(belt, decoded)
    }
}
