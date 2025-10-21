import Foundation

/// Main input structure for pulley FEA calculation
/// Converted from C++ sPulleyInput in sPulleyInput.h
public struct PulleyInput: Codable {
    public let pulleyType: PulleyType
    public let belt: Belt
    public let shell: ShellInput
    public let shaft: ShaftInput
    public let endDiskA: EndDiskAssembly
    public let endDiskB: EndDiskAssembly
    public let centerDisks: [CenterDisk]
    public let load: AppliedLoad
    public let overhungLoad: OverhungLoad?
    public let finiteElementOptions: FiniteElementOptions

    public init(
        pulleyType: PulleyType,
        belt: Belt,
        shell: ShellInput,
        shaft: ShaftInput,
        endDiskA: EndDiskAssembly,
        endDiskB: EndDiskAssembly,
        centerDisks: [CenterDisk],
        load: AppliedLoad,
        overhungLoad: OverhungLoad?,
        finiteElementOptions: FiniteElementOptions
    ) {
        self.pulleyType = pulleyType
        self.belt = belt
        self.shell = shell
        self.shaft = shaft
        self.endDiskA = endDiskA
        self.endDiskB = endDiskB
        self.centerDisks = centerDisks
        self.load = load
        self.overhungLoad = overhungLoad
        self.finiteElementOptions = finiteElementOptions
    }
}

/// Shell component input parameters
public struct ShellInput: Codable, Equatable {
    public let outerDiameter: Double
    public let faceWidth: Double
    public let gapWidth: Double
    public let thickness: Double
    public let distanceWeldFromEndDisk: Double
    public let material: Material
    public let useNumericalIntegration: Bool
    public let divisions: Int

    public init(
        outerDiameter: Double,
        faceWidth: Double,
        gapWidth: Double,
        thickness: Double,
        distanceWeldFromEndDisk: Double,
        material: Material,
        useNumericalIntegration: Bool,
        divisions: Int
    ) {
        self.outerDiameter = outerDiameter
        self.faceWidth = faceWidth
        self.gapWidth = gapWidth
        self.thickness = thickness
        self.distanceWeldFromEndDisk = distanceWeldFromEndDisk
        self.material = material
        self.useNumericalIntegration = useNumericalIntegration
        self.divisions = divisions
    }
}

/// Shaft component input parameters
public struct ShaftInput: Codable, Equatable {
    public let diameterAtCenter: Double
    public let diameterAtEndDisk: Double
    public let diameterAtSupport: Double
    public let diameterAtExtensionA: Double
    public let diameterAtExtensionB: Double
    public let centersEndDisk: Double
    public let centersSupport: Double
    public let axialExtensionA: Double
    public let axialExtensionB: Double
    public let landingEndDisk: Double
    public let landingExtensionA: Double
    public let landingExtensionB: Double
    public let material: Material
    public let constrainedAt: String
    public let divisions: Int
    public let fatigueFactor: FatigueFactor
    public let combineStressAS1403: Bool

    public init(
        diameterAtCenter: Double,
        diameterAtEndDisk: Double,
        diameterAtSupport: Double,
        diameterAtExtensionA: Double,
        diameterAtExtensionB: Double,
        centersEndDisk: Double,
        centersSupport: Double,
        axialExtensionA: Double,
        axialExtensionB: Double,
        landingEndDisk: Double,
        landingExtensionA: Double,
        landingExtensionB: Double,
        material: Material,
        constrainedAt: String,
        divisions: Int,
        fatigueFactor: FatigueFactor,
        combineStressAS1403: Bool
    ) {
        self.diameterAtCenter = diameterAtCenter
        self.diameterAtEndDisk = diameterAtEndDisk
        self.diameterAtSupport = diameterAtSupport
        self.diameterAtExtensionA = diameterAtExtensionA
        self.diameterAtExtensionB = diameterAtExtensionB
        self.centersEndDisk = centersEndDisk
        self.centersSupport = centersSupport
        self.axialExtensionA = axialExtensionA
        self.axialExtensionB = axialExtensionB
        self.landingEndDisk = landingEndDisk
        self.landingExtensionA = landingExtensionA
        self.landingExtensionB = landingExtensionB
        self.material = material
        self.constrainedAt = constrainedAt
        self.divisions = divisions
        self.fatigueFactor = fatigueFactor
        self.combineStressAS1403 = combineStressAS1403
    }
}

/// Fatigue factors for shaft components
public struct FatigueFactor: Codable, Equatable {
    public let lockingAssembly: Double
    public let bearing: Double
    public let coupling: Double

    public init(lockingAssembly: Double, bearing: Double, coupling: Double) {
        self.lockingAssembly = lockingAssembly
        self.bearing = bearing
        self.coupling = coupling
    }
}

/// End disk assembly configuration
public struct EndDiskAssembly: Codable, Equatable {
    public let useNumericalIntegration: Bool
    public let hub: Hub
    public let notchFactorInner: Int
    public let notchFactorOuter: Int
    public let material: Material
    public let divisions: Int
    public let diameter: [Double]
    public let width: [Double]
    public let pressFit: Double
    public let pulleyType: PulleyType
    public let bearing: Bearing
    public let lockingAssembly: LockingAssembly

    public init(
        useNumericalIntegration: Bool,
        hub: Hub,
        notchFactorInner: Int,
        notchFactorOuter: Int,
        material: Material,
        divisions: Int,
        diameter: [Double],
        width: [Double],
        pressFit: Double,
        pulleyType: PulleyType,
        bearing: Bearing,
        lockingAssembly: LockingAssembly
    ) {
        self.useNumericalIntegration = useNumericalIntegration
        self.hub = hub
        self.notchFactorInner = notchFactorInner
        self.notchFactorOuter = notchFactorOuter
        self.material = material
        self.divisions = divisions
        self.diameter = diameter
        self.width = width
        self.pressFit = pressFit
        self.pulleyType = pulleyType
        self.bearing = bearing
        self.lockingAssembly = lockingAssembly
    }
}

/// Bearing specification
public struct Bearing: Codable, Equatable {
    public let dynamicCapacity: Double
    public let width: Double

    public init(dynamicCapacity: Double, width: Double) {
        self.dynamicCapacity = dynamicCapacity
        self.width = width
    }
}

/// Center disk configuration
public struct CenterDisk: Codable, Equatable {
    public let number: Int
    public let width: Double
    public let innerDiameter: Double
    public let outerDiameter: Double

    public init(number: Int, width: Double, innerDiameter: Double, outerDiameter: Double) {
        self.number = number
        self.width = width
        self.innerDiameter = innerDiameter
        self.outerDiameter = outerDiameter
    }
}

/// Overhung load specification
public struct OverhungLoad: Codable, Equatable {
    public let arm: Double
    public let magnitude: Double
    public let direction: Double

    public init(arm: Double, magnitude: Double, direction: Double) {
        self.arm = arm
        self.magnitude = magnitude
        self.direction = direction
    }
}

/// Load conditions for different operating scenarios
public struct Load: Codable, Equatable {
    public let t1: Double
    public let t2: Double

    public init(t1: Double, t2: Double) {
        self.t1 = t1
        self.t2 = t2
    }
}

/// Applied loads for different operating conditions
public struct AppliedLoad: Codable, Equatable {
    public let design: Load
    public let run: Load
    public let max: Load

    public init(design: Load, run: Load, max: Load) {
        self.design = design
        self.run = run
        self.max = max
    }
}

/// Finite element calculation options
public struct FiniteElementOptions: Codable, Equatable {
    public let numberOfModes: Int
    public let useMultithreading: Bool
    public let numberOfThreads: Int

    public init(numberOfModes: Int, useMultithreading: Bool, numberOfThreads: Int) {
        self.numberOfModes = numberOfModes
        self.useMultithreading = useMultithreading
        self.numberOfThreads = numberOfThreads
    }
}
