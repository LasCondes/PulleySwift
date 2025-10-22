# PulleySwift

A modern Swift implementation of pulley finite element analysis (FEA) for conveyor belt systems.

## Overview

PulleySwift is a Swift-based rewrite of the C++ PulleyMavenWebService, providing structural analysis for conveyor pulleys using finite element methods. The project aims to bring modern Swift features, improved maintainability, and cross-platform capabilities to pulley engineering calculations.

## Architecture

The project is organized into modular Swift packages:

### PulleyCore
Core domain models and data structures:
- `Material` - Material properties (Young's modulus, yield strength, density, etc.)
- `Belt` - Belt configuration and loading parameters
- `Hub` - Hub geometry specifications
- `PulleyInput` - Complete input specification for FEA analysis
- `PulleyType` - Pulley configuration types (live shaft, dead shaft, stub, etc.)
- Supporting structures: `ShellInput`, `ShaftInput`, `EndDiskAssembly`, etc.

### PulleyStandards
Engineering design standards:
- `Criterium` - Base protocol for design criteria
- `ANSIStandard` - ANSI shaft design with Marin factors
- `DIN15018Standard` - DIN 15018 crane code for weld fatigue
- `AS1403Standard` - AS 1403 Australian pulley standard with stress concentration

### PulleyBOM
Bill of materials and costing:
- `MaterialDatabase` - Material lookup and search
- Plate thickness and cost optimization
- Component costing calculations

### FEA Engine (External Dependency)
**[AxiSymFEA](https://github.com/LasCondes/AxiSymFEA)** - Standalone axisymmetric FEA library:
- Transfer Matrix Method for axisymmetric structures
- Direct stiffness method for beam elements
- Three element types: Disk, Shell, Shaft
- LAPACK solver using Accelerate framework
- Fourier mode decomposition

## Requirements

- Swift 6.2+
- macOS 13+ or iOS 16+
- Xcode 15+ (for development)

## Building

```bash
swift build
```

## Testing

```bash
swift test
```

All tests pass (13 tests):
- PulleyCoreTests: 5 tests
- PulleyStandardsTests: 8 tests

## Current Status

✅ Completed:
- Project structure and Swift Package Manager setup
- Core domain models (Material, Belt, Hub, PulleyInput, etc.)
- FEA infrastructure extracted to [AxiSymFEA](https://github.com/LasCondes/AxiSymFEA)
- Engineering standards (ANSI, DIN15018, AS1403)
- BOM interface definitions
- Unit tests for core models and standards
- JSON Codable support for all data structures
- Example shaft FEA model

📋 Planned:
- Complete pulley-specific FEA models
- Web service layer
- Integration tests
- Material database implementation

## Migration from C++

This project is being converted from the C++ codebase at `PulleyMavenWebService`. Key conversion strategies:

1. **Data Models**: Direct Swift struct conversion with Codable support (replaces Boost.PropertyTree)
2. **FEA Engine**: Protocol-based design with potential C++ interop for Eigen-dependent calculations
3. **Numerical Computing**: Evaluating Apple Accelerate framework vs C++ interop with Eigen
4. **JSON I/O**: Native Swift Codable (cleaner than Boost.PropertyTree)

## Design Decisions

### Hybrid vs Pure Swift Approach

We're evaluating two approaches for the numerical computing core:

**Option A: Hybrid (Recommended)**
- Keep Eigen-dependent FEA code in C++
- Wrap via Swift 5.9+ C++ interoperability
- Expose Swift-friendly APIs
- Lower risk, faster initial development

**Option B: Pure Swift**
- Use Apple Accelerate framework (BLAS/LAPACK)
- Build custom sparse matrix layer
- Reimplement transfer matrix algorithms
- Higher risk, better long-term maintainability

## Contributing

This is an active conversion project. Contributions are welcome for:
- FEA element implementations
- Engineering standards calculations
- Test coverage
- Documentation

## License

(License to be determined - consult original PulleyMavenWebService project)

## References

- Original C++ implementation: PulleyMavenWebService
- Engineering standards: ANSI, DIN 15018, AS 1403
- Numerical methods: Transfer Matrix Method, Finite Element Analysis
