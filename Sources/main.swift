import Foundation

// MARK: - Data Models

/// Represents system information collected from macOS
struct SystemInfo {
    let osName: String
    let osVersion: String
    let hostname: String
    let username: String
    let cpuModel: String
    
    /// Checks if all system information fields are empty
    var isEmpty: Bool {
        return osName.isEmpty && osVersion.isEmpty && 
               hostname.isEmpty && username.isEmpty && 
               cpuModel.isEmpty
    }
}

// MARK: - System Information Collector

/// Collects system information from macOS using native APIs
class SystemInfoCollector {
    
    /// Retrieves operating system name and version
    /// - Returns: A tuple containing OS name and version
    func getOSInfo() -> (name: String, version: String) {
        let processInfo = ProcessInfo.processInfo
        let osName = "macOS"
        
        // Extract version number from the operating system version
        let version = processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        
        return (name: osName, version: versionString)
    }
    
    /// Retrieves the system hostname
    /// - Returns: The hostname of the system
    func getHostname() -> String {
        let processInfo = ProcessInfo.processInfo
        return processInfo.hostName
    }
    
    /// Retrieves the current username
    /// - Returns: The username of the current user
    func getUsername() -> String {
        return NSUserName()
    }
    
    /// Retrieves CPU model information using sysctl
    /// - Returns: The CPU model string
    func getCPUModel() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        
        guard size > 0 else {
            return "Unknown"
        }
        
        var machine = [CChar](repeating: 0, count: size)
        let result = sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        
        if result == 0 {
            return String(cString: machine).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "Unknown"
        }
    }
    
    /// Collects all system information with fallback handling
    /// - Returns: A SystemInfo struct containing all collected information
    func collect() -> SystemInfo {
        let osInfo = getOSInfo()
        let hostname = getHostname()
        let username = getUsername()
        let cpuModel = getCPUModel()
        
        // Apply fallback values if any field is empty
        return SystemInfo(
            osName: osInfo.name.isEmpty ? "Unknown" : osInfo.name,
            osVersion: osInfo.version.isEmpty ? "Unknown" : osInfo.version,
            hostname: hostname.isEmpty ? "Unknown" : hostname,
            username: username.isEmpty ? "Unknown" : username,
            cpuModel: cpuModel.isEmpty ? "Unknown" : cpuModel
        )
    }
}

// MARK: - Color Formatting

/// ANSI color codes for terminal output
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

/// Handles ANSI color code application and text formatting
class ColorFormatter {
    
    /// Wraps text with ANSI color codes
    /// - Parameters:
    ///   - text: The text to colorize
    ///   - color: The ANSI color to apply
    /// - Returns: The text wrapped with color codes and reset code
    func colorize(_ text: String, color: ANSIColor) -> String {
        return "\(color.rawValue)\(text)\(ANSIColor.reset.rawValue)"
    }
    
    /// Formats a label with cyan color
    /// - Parameter label: The label text to format
    /// - Returns: The formatted label with cyan color
    func formatLabel(_ label: String) -> String {
        return colorize(label, color: .cyan)
    }
    
    /// Formats a value with white color
    /// - Parameter value: The value text to format
    /// - Returns: The formatted value with white color
    func formatValue(_ value: String) -> String {
        return colorize(value, color: .white)
    }
    
    /// Formats a label-value pair into a single line
    /// - Parameters:
    ///   - label: The label text
    ///   - value: The value text
    /// - Returns: A formatted string with label and value in distinct colors
    func formatInfoLine(_ label: String, _ value: String) -> String {
        return "\(formatLabel(label)): \(formatValue(value))"
    }
}

// MARK: - ASCII Art Provider

/// Provides ASCII art designs for display
class ASCIIArtProvider {
    
    /// Returns the default macOS/Apple ASCII art
    /// - Returns: An array of strings representing lines of ASCII art
    func getMacOSArt() -> [String] {
        return [
            "                    'c.",
            "                 ,xNMM.",
            "               .OMMMMo",
            "               OMMM0,",
            "     .;loddo:' loolloddol;.",
            "   cKMMMMMMMMMMNWMMMMMMMMMM0:",
            " .KMMMMMMMMMMMMMMMMMMMMMMMWd.",
            " XMMMMMMMMMMMMMMMMMMMMMMMX.",
            ";MMMMMMMMMMMMMMMMMMMMMMMM:",
            ":MMMMMMMMMMMMMMMMMMMMMMMM:",
            ".MMMMMMMMMMMMMMMMMMMMMMMMX.",
            " kMMMMMMMMMMMMMMMMMMMMMMMMWd.",
            " .XMMMMMMMMMMMMMMMMMMMMMMMMMMk",
            "  .XMMMMMMMMMMMMMMMMMMMMMMMMK.",
            "    kMMMMMMMMMMMMMMMMMMMMMMd",
            "     ;KMMMMMMMWXXWMMMMMMMk.",
            "       .cooc,.    .,coo:."
        ]
    }
    
    /// Applies color to all lines of ASCII art
    /// - Parameters:
    ///   - lines: The array of ASCII art lines
    ///   - color: The ANSI color to apply
    /// - Returns: An array of colorized ASCII art lines
    func colorizeArt(_ lines: [String], color: ANSIColor) -> [String] {
        return lines.map { line in
            "\(color.rawValue)\(line)\(ANSIColor.reset.rawValue)"
        }
    }
}

// MARK: - Display Renderer

/// Combines ASCII art and system information into final output
class DisplayRenderer {
    let artProvider: ASCIIArtProvider
    let colorFormatter: ColorFormatter
    
    /// Initializes the DisplayRenderer with required dependencies
    /// - Parameters:
    ///   - artProvider: The ASCII art provider
    ///   - colorFormatter: The color formatter
    init(artProvider: ASCIIArtProvider, colorFormatter: ColorFormatter) {
        self.artProvider = artProvider
        self.colorFormatter = colorFormatter
    }
    
    /// Combines ASCII art and system information side-by-side
    /// - Parameters:
    ///   - art: Array of ASCII art lines
    ///   - info: Array of system information lines
    /// - Returns: Array of combined lines with proper alignment
    func combineArtAndInfo(art: [String], info: [String]) -> [String] {
        var combined: [String] = []
        
        // Calculate the maximum width of art lines (without ANSI codes)
        let artWidth = art.map { stripANSICodes($0).count }.max() ?? 0
        let padding = 4 // Space between art and info
        
        // Determine the maximum number of lines
        let maxLines = max(art.count, info.count)
        
        for i in 0..<maxLines {
            var line = ""
            
            // Add art line or empty space if art has fewer lines
            if i < art.count {
                let artLine = art[i]
                let artLineStripped = stripANSICodes(artLine)
                line += artLine
                // Add padding to align with the widest art line
                let spacesToAdd = artWidth - artLineStripped.count + padding
                line += String(repeating: " ", count: spacesToAdd)
            } else {
                // Art has ended, add empty space
                line += String(repeating: " ", count: artWidth + padding)
            }
            
            // Add info line if available
            if i < info.count {
                line += info[i]
            }
            
            combined.append(line)
        }
        
        return combined
    }
    
    /// Strips ANSI color codes from a string for length calculation
    /// - Parameter text: The text containing ANSI codes
    /// - Returns: The text without ANSI codes
    private func stripANSICodes(_ text: String) -> String {
        // Regular expression to match ANSI escape sequences
        let pattern = "\u{001B}\\[[0-9;]*m"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
    }
    
    /// Prints lines to the terminal
    /// - Parameter lines: Array of lines to print
    func printToTerminal(_ lines: [String]) {
        for line in lines {
            print(line)
        }
    }
    
    /// Orchestrates the complete display process
    /// - Parameter systemInfo: The system information to display
    func render(systemInfo: SystemInfo) {
        // Get and colorize ASCII art
        let art = artProvider.getMacOSArt()
        let colorizedArt = artProvider.colorizeArt(art, color: .green)
        
        // Format system information lines
        let infoLines = [
            colorFormatter.formatInfoLine("OS", "\(systemInfo.osName) \(systemInfo.osVersion)"),
            colorFormatter.formatInfoLine("Host", systemInfo.hostname),
            colorFormatter.formatInfoLine("User", systemInfo.username),
            colorFormatter.formatInfoLine("CPU", systemInfo.cpuModel)
        ]
        
        // Combine art and info
        let combined = combineArtAndInfo(art: colorizedArt, info: infoLines)
        
        // Print to terminal
        printToTerminal(combined)
    }
}

// MARK: - Main Entry Point

// Instantiate SystemInfoCollector and collect system info
let collector = SystemInfoCollector()
let systemInfo = collector.collect()

// Instantiate ColorFormatter, ASCIIArtProvider, and DisplayRenderer
let colorFormatter = ColorFormatter()
let artProvider = ASCIIArtProvider()
let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)

// Call DisplayRenderer.render() with collected system info
renderer.render(systemInfo: systemInfo)
