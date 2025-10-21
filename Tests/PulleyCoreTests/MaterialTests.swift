import XCTest
@testable import PulleyCore

final class MaterialTests: XCTestCase {
    func testMaterialInitialization() {
        let material = Material(
            itemNumber: "PM00000050",
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            yieldStrength: 355.0,
            enduranceLimit: 200.0,
            ultimateStrength: 490.0,
            density: 7850.0,
            baseStress: 180.0
        )

        XCTAssertEqual(material.itemNumber, "PM00000050")
        XCTAssertEqual(material.youngsModulus, 210000.0)
        XCTAssertEqual(material.poissonsRatio, 0.3)
        XCTAssertEqual(material.yieldStrength, 355.0)
    }

    func testMaterialJSONEncoding() throws {
        let material = Material(
            itemNumber: "PM00000050",
            youngsModulus: 210000.0,
            poissonsRatio: 0.3,
            yieldStrength: 355.0,
            enduranceLimit: 200.0,
            ultimateStrength: 490.0,
            density: 7850.0,
            baseStress: 180.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(material)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Material.self, from: data)

        XCTAssertEqual(material, decoded)
    }

    func testMaterialJSONCodingKeys() throws {
        let jsonString = """
        {
            "itemNumber": "PM00000050",
            "E": 210000.0,
            "nu": 0.3,
            "yieldStrength": 355.0,
            "enduranceLimit": 200.0,
            "ultimateStrength": 490.0,
            "density": 7850.0,
            "sB0": 180.0
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let material = try decoder.decode(Material.self, from: data)

        XCTAssertEqual(material.youngsModulus, 210000.0)
        XCTAssertEqual(material.poissonsRatio, 0.3)
        XCTAssertEqual(material.baseStress, 180.0)
    }
}
