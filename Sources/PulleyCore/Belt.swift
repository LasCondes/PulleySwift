import Foundation

/// Belt configuration and loading parameters
/// Converted from C++ sBelt struct in sPulleyInput.h
public struct Belt: Codable, Equatable {
    /// Belt width in mm
    public let width: Double

    /// Wrap angle in radians
    public let wrapAngle: Double

    /// Belt thickness in mm
    public let thickness: Double

    /// Belt speed in m/s
    public let speed: Double

    /// Approach angle in radians
    public let approachAngle: Double

    /// Lagging thickness in mm
    public let laggingThickness: Double

    /// True if torque reversal conditions apply
    public let torqueReversal: Bool

    /// True if rotation is clockwise
    public let rotationClockwise: Bool

    public init(
        width: Double,
        wrapAngle: Double,
        thickness: Double,
        speed: Double,
        approachAngle: Double,
        laggingThickness: Double,
        torqueReversal: Bool,
        rotationClockwise: Bool
    ) {
        self.width = width
        self.wrapAngle = wrapAngle
        self.thickness = thickness
        self.speed = speed
        self.approachAngle = approachAngle
        self.laggingThickness = laggingThickness
        self.torqueReversal = torqueReversal
        self.rotationClockwise = rotationClockwise
    }

    enum CodingKeys: String, CodingKey {
        case width
        case wrapAngle
        case thickness
        case speed
        case approachAngle
        case laggingThickness
        case torqueReversal
        case rotationClockwise = "rotationCW"
    }
}
