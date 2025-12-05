# Design Document: swift_fetch

## Overview

swift_fetch is a command-line system information display tool for macOS, written in Swift. The tool retrieves system metrics (OS version, hostname, username, CPU model) and displays them in a formatted layout alongside colorized ASCII art. The design emphasizes simplicity, modularity, and native macOS integration using Swift's Foundation framework and system APIs.

## Architecture

The application follows a simple layered architecture:

1. **Main Entry Point**: Orchestrates the execution flow
2. **System Information Layer**: Retrieves system metrics using macOS APIs
3. **Presentation Layer**: Formats and colorizes output
4. **Display Layer**: Renders ASCII art and system information side-by-side

The architecture is designed for a proof-of-concept with clear separation between data retrieval, formatting, and display logic.

```
┌─────────────────┐
│   main.swift    │
└────────┬────────┘
         │
    ┌────▼─────────────────────┐
    │  SystemInfoCollector     │
    │  - Retrieves OS info     │
    │  - Retrieves hostname    │
    │  - Retrieves username    │
    │  - Retrieves CPU info    │
    └────────┬─────────────────┘
             │
    ┌────────▼─────────────────┐
    │  OutputFormatter         │
    │  - Applies ANSI colors   │
    │  - Formats labels/values │
    │  - Manages layout        │
    └────────┬─────────────────┘
             │
    ┌────────▼─────────────────┐
    │  DisplayRenderer         │
    │  - Renders ASCII art     │
    │  - Combines art + info   │
    │  - Outputs to terminal   │
    └──────────────────────────┘
```

## Components and Interfaces

### SystemInfoCollector

Responsible for retrieving system information from macOS.

```swift
struct SystemInfo {
    let osName: String
    let osVersion: String
    let hostname: String
    let username: String
    let cpuModel: String
}

class SystemInfoCollector {
    func collect() -> SystemInfo
    func getOSInfo() -> (name: String, version: String)
    func getHostname() -> String
    func getUsername() -> String
    func getCPUModel() -> String
}
```

**Implementation approach:**
- Use `ProcessInfo` for OS version and hostname
- Use `NSUserName()` for username
- Use `sysctl` or shell commands for CPU information
- Return fallback values (e.g., "Unknown") when data is unavailable

### ColorFormatter

Handles ANSI color code application and text formatting.

```swift
enum ANSIColor: String {
    case reset = "\u{001B}[0m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case magenta = "\u{001B}[35m"
    case cyan = "\u{001B}[36m"
    case white = "\u{001B}[37m"
}

class ColorFormatter {
    func colorize(_ text: String, color: ANSIColor) -> String
    func formatLabel(_ label: String) -> String
    func formatValue(_ value: String) -> String
    func formatInfoLine(_ label: String, _ value: String) -> String
}
```

**Implementation approach:**
- Wrap text with ANSI escape codes
- Always append reset code after colored text
- Use consistent colors: labels in cyan, values in white

### ASCIIArtProvider

Provides ASCII art designs for display.

```swift
class ASCIIArtProvider {
    func getMacOSArt() -> [String]
    func colorizeArt(_ lines: [String], color: ANSIColor) -> [String]
}
```

**Implementation approach:**
- Store ASCII art as multi-line string arrays
- Provide a simple Apple logo or macOS-themed design
- Apply color to each line of the art

### DisplayRenderer

Combines ASCII art and system information into final output.

```swift
class DisplayRenderer {
    let artProvider: ASCIIArtProvider
    let colorFormatter: ColorFormatter
    
    func render(systemInfo: SystemInfo)
    func combineArtAndInfo(art: [String], info: [String]) -> [String]
    func printToTerminal(_ lines: [String])
}
```

**Implementation approach:**
- Place ASCII art on the left, system info on the right
- Pad lines to ensure proper alignment
- Handle cases where art has more/fewer lines than info

## Data Models

### SystemInfo

```swift
struct SystemInfo {
    let osName: String
    let osVersion: String
    let hostname: String
    let username: String
    let cpuModel: String
    
    var isEmpty: Bool {
        return osName.isEmpty && osVersion.isEmpty && 
               hostname.isEmpty && username.isEmpty && 
               cpuModel.isEmpty
    }
}
```

This is the primary data structure holding all retrieved system metrics.


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: System information completeness
*For any* execution of the system info collector on macOS, all required fields (OS name, OS version, hostname, username, CPU model) should be populated with non-empty values or appropriate fallback values.
**Validates: Requirements 1.2, 1.3, 1.4, 1.5, 4.1**

### Property 2: Color code application
*For any* text string that is colorized, the output should contain valid ANSI escape sequences that match the standard format `\u{001B}[<code>m`.
**Validates: Requirements 2.1, 2.3, 3.3**

### Property 3: Color reset prevents bleeding
*For any* text string that is colorized, the output should end with the ANSI reset code `\u{001B}[0m` to prevent color bleeding.
**Validates: Requirements 2.4**

### Property 4: Label and value color distinction
*For any* label-value pair formatted for display, the label color code should differ from the value color code.
**Validates: Requirements 2.2**

### Property 5: Information formatting consistency
*For any* set of label-value pairs formatted for display, all pairs should have consistent spacing between labels and values, and all lines should be properly aligned.
**Validates: Requirements 6.1, 6.2**

### Property 6: Art and info alignment without overlap
*For any* ASCII art lines and system info lines combined for display, the resulting output should position them side-by-side with consistent spacing and no character overlap.
**Validates: Requirements 3.2, 6.3**

### Property 7: Fallback on retrieval errors
*For any* system information field that fails to retrieve, the collector should return a non-empty fallback value (e.g., "Unknown") instead of an empty string or throwing an error.
**Validates: Requirements 4.3**

## Error Handling

The application should handle errors gracefully without crashing:

1. **System Information Retrieval Failures**: If any system API call fails, return fallback values like "Unknown" or "N/A"
2. **Missing Data**: Display fallback messages for unavailable data rather than empty fields
3. **Terminal Compatibility**: Assume standard ANSI color support; no special handling for non-color terminals in this POC

Error handling strategy:
- Use Swift's optional types and nil-coalescing for safe value retrieval
- Wrap system calls in try-catch blocks where necessary
- Never crash on missing data—always provide fallback values

## Testing Strategy

### Unit Testing

Unit tests will verify specific behaviors and edge cases:

1. **SystemInfoCollector tests**:
   - Test that each retrieval method returns non-empty strings
   - Test fallback behavior when system calls fail
   - Test SystemInfo struct initialization

2. **ColorFormatter tests**:
   - Test that colorize() adds correct ANSI codes
   - Test that reset codes are always appended
   - Test label vs value color distinction
   - Test formatInfoLine() produces expected format

3. **ASCIIArtProvider tests**:
   - Test that getMacOSArt() returns non-empty array
   - Test that colorizeArt() applies colors to all lines

4. **DisplayRenderer tests**:
   - Test combineArtAndInfo() alignment logic
   - Test handling of mismatched line counts (art vs info)

### Property-Based Testing

Property-based tests will verify universal properties across many inputs using **swift-check**, a QuickCheck-inspired property testing library for Swift.

Each property-based test will:
- Run a minimum of 100 iterations with randomly generated inputs
- Be tagged with a comment referencing the design document property
- Verify the correctness properties defined above

**Property test implementations**:

1. **Property 1 test**: Generate random system states, verify all SystemInfo fields are non-empty
2. **Property 2 test**: Generate random strings, colorize them, verify ANSI codes present
3. **Property 3 test**: Generate random strings, colorize them, verify reset code at end
4. **Property 4 test**: Generate random label-value pairs, verify different color codes
5. **Property 5 test**: Generate random sets of label-value pairs, verify consistent spacing
6. **Property 6 test**: Generate random art and info lines, verify no overlap in combined output
7. **Property 7 test**: Simulate retrieval failures, verify fallback values returned

### Integration Testing

Integration tests will verify end-to-end behavior:
- Execute the complete tool and verify output contains expected sections
- Verify output is properly formatted with colors and ASCII art
- Verify the tool completes without errors

### Testing Framework

- **Unit tests**: Swift's built-in XCTest framework
- **Property-based tests**: swift-check library (https://github.com/typelift/SwiftCheck)
- **Test execution**: `swift test` command

## Implementation Notes

### Build System

Use Swift Package Manager (SPM) for dependency management and building:
- Create a `Package.swift` manifest
- Define the executable target
- Include swift-check as a test dependency

### Execution Flow

1. Main entry point calls SystemInfoCollector.collect()
2. SystemInfo is passed to DisplayRenderer
3. DisplayRenderer retrieves ASCII art from ASCIIArtProvider
4. DisplayRenderer formats info lines using ColorFormatter
5. DisplayRenderer combines art and info, prints to stdout

### Performance Considerations

For this POC, performance is not a primary concern. The tool should:
- Execute in under 1 second on typical macOS systems
- Minimize system calls by collecting all info once
- Use simple string operations for formatting

### Future Enhancements (Out of Scope for POC)

- Support for additional system metrics (memory, disk, uptime)
- Customizable color schemes
- Multiple ASCII art options
- Configuration file support
- Linux/Windows compatibility
