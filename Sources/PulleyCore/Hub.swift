import Foundation

/// Hub geometry specification
/// Converted from C++ sHub struct in sPulleyInput.h
public struct Hub: Codable, Equatable {
    /// Outer diameter in mm
    public let outerDiameter: Double

    /// Outer width in mm
    public let outerWidth: Double

    /// Inner diameter in mm
    public let innerDiameter: Double

    /// Inner width in mm
    public let innerWidth: Double

    public init(
        outerDiameter: Double,
        outerWidth: Double,
        innerDiameter: Double,
        innerWidth: Double
    ) {
        self.outerDiameter = outerDiameter
        self.outerWidth = outerWidth
        self.innerDiameter = innerDiameter
        self.innerWidth = innerWidth
    }
}
