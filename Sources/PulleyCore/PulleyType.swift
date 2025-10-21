import Foundation

/// Pulley configuration types
/// Converted from C++ ePulleyType enum in sPulleyInput.h
public enum PulleyType: String, Codable {
    /// Live shaft configuration - shaft rotates with pulley
    case liveShaft

    /// Dead shaft configuration - shaft is stationary
    case deadShaft

    /// Stub shaft configuration
    case stub

    /// Stub without disk
    case stubNoDisk

    /// Deflection analysis mode
    case deflection
}
