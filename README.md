# swift_fetch

```
         .:'
    __ :'__
 .'`__`-'__``.
:__________.-'
:_________:
 :_________`-;      A Swift-powered system info tool
  `.__.-.__.'       for macOS
```

A fast, colorful command-line system information display tool written in Swift. Inspired by neofetch, swift_fetch retrieves comprehensive macOS system details and displays them alongside beautiful ASCII art.

## Features

- 🎨 **Colorized Output** - ANSI color-coded labels and values for easy reading
- 🖼️ **ASCII Art** - Eye-catching Apple logo displayed alongside system info
- 📊 **Comprehensive Data** - Collects 21+ system metrics
- ⚡ **Native Swift** - Built with Swift for optimal macOS integration
- 🧪 **Well Tested** - Includes unit tests and property-based tests

## Usage

Run the tool from your terminal:

```bash
swift run
```

Or build a release version:

```bash
./bin/build-release.sh
./release/swift-fetch
```

The tool will display your system information in a formatted layout with ASCII art.

## Building

### Requirements

- macOS 12.0 or later
- Swift 5.9 or later
- Xcode Command Line Tools

### Build Instructions

1. Clone the repository:
```bash
git clone <repository-url>
cd swift_fetch
```

2. Build the project:
```bash
swift build
```

3. Run the executable:
```bash
swift run
```

For a release build with optimizations, use the build script:
```bash
./bin/build-release.sh
```

This will:
- Build the optimized release binary in `.build/release/`
- Copy the executable to `release/swift-fetch`

Then run it:
```bash
./release/swift-fetch
```

Or manually build without the script:
```bash
swift build -c release
.build/release/swift-fetch
```

## Collected System Information

swift_fetch retrieves the following system metrics:

### Operating System
- **OS Name** - Operating system name (macOS)
- **OS Version** - Version number (e.g., 14.1)
- **OS Build** - Build identifier
- **Architecture** - Processor architecture (arm64/x86_64)

### Hardware
- **Host Model** - Mac model identifier (e.g., Mac15,11)
- **CPU Model** - Processor name and specifications
- **GPU Model** - Graphics card information
- **Memory** - Used and total RAM in MiB

### System Environment
- **Hostname** - Computer name on the network
- **Username** - Current logged-in user
- **Kernel** - Kernel version
- **Uptime** - Time since last boot
- **Packages** - Homebrew package count

### Display & Desktop
- **Resolution** - Screen resolution (WIDTHxHEIGHT)
- **Desktop Environment** - Aqua (macOS standard)
- **Window Manager** - Quartz Compositor
- **WM Theme** - Current theme (Light/Dark mode)

### Terminal
- **Terminal** - Terminal application name
- **Terminal Font** - Font name and size (if detectable)
- **Shell** - Shell name and version

## Testing

swift_fetch includes a comprehensive test suite with both unit tests and property-based tests.

### Running Tests

Run all tests:
```bash
swift test
```

Run tests with verbose output:
```bash
swift test --verbose
```

### Test Coverage

**Unit Tests** (16 tests)
- SystemInfoCollector functionality
- ColorFormatter ANSI code application
- ASCIIArtProvider art generation
- DisplayRenderer alignment logic
- End-to-end integration test

**Property-Based Tests** (7 properties, 25 iterations each)

Using [SwiftCheck](https://github.com/typelift/SwiftCheck), the following correctness properties are verified:

1. **Comprehensive system information completeness** - All fields populated or have fallback values
2. **Color code application** - Valid ANSI escape sequences in colorized output
3. **Color reset prevents bleeding** - Reset codes properly terminate color sequences
4. **Label and value color distinction** - Labels and values use different colors
5. **Information formatting consistency** - Consistent spacing and alignment
6. **Art and info alignment without overlap** - Side-by-side display without character overlap
7. **Fallback on retrieval errors** - Graceful handling of missing data

## Architecture

swift_fetch follows a modular architecture:

- **SystemInfoCollector** - Retrieves system metrics using macOS APIs and shell commands
- **ColorFormatter** - Applies ANSI color codes to text
- **ASCIIArtProvider** - Provides and colorizes ASCII art
- **DisplayRenderer** - Combines art and info into final output

## Implementation Details

The tool uses:
- `ProcessInfo` for OS version and basic system info
- `sysctl` for hardware details (CPU, memory, kernel)
- `uname` for architecture and kernel version
- Shell commands for uptime, packages, and display info
- Environment variables for shell and terminal detection
- CoreGraphics API for screen resolution

## License

[Add your license here]

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

Inspired by [neofetch](https://github.com/dylanaraps/neofetch) and the system info tool community.
