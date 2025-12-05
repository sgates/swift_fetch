import Foundation
import CoreGraphics

// MARK: - Data Models

/// Represents system information collected from macOS
struct SystemInfo {
    // OS/Hardware details
    let osName: String
    let osVersion: String
    let osBuild: String
    let architecture: String
    let hostModel: String
    let hostname: String
    let username: String
    
    // System environment
    let kernel: String
    let uptime: String
    let packages: String
    let shell: String
    
    // Display configuration
    let resolution: String
    let de: String
    let wm: String
    let wmTheme: String
    
    // Terminal environment
    let terminal: String
    let terminalFont: String
    
    // Hardware resources
    let cpuModel: String
    let gpuModel: String
    let memoryUsed: String
    let memoryTotal: String
    
    /// Checks if critical system information fields are empty
    var isEmpty: Bool {
        return osName.isEmpty && osVersion.isEmpty && 
               hostname.isEmpty && username.isEmpty
    }
}

// MARK: - System Information Collector

/// Collects system information from macOS using native APIs
class SystemInfoCollector {
    
    /// Retrieves operating system name, version, build number, and architecture
    /// - Returns: A tuple containing OS name, version, build number, and architecture
    func getOSInfo() -> (name: String, version: String, build: String, architecture: String) {
        let processInfo = ProcessInfo.processInfo
        let osName = "macOS"
        
        // Extract version number from the operating system version
        let version = processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        
        // Get build number using sysctl
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var buildNumber = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &buildNumber, &size, nil, 0)
        let build = String(cString: buildNumber).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get architecture using uname
        var systemInfo = utsname()
        uname(&systemInfo)
        let architecture = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        
        return (name: osName, version: versionString, build: build.isEmpty ? "Unknown" : build, architecture: architecture.isEmpty ? "Unknown" : architecture)
    }
    
    /// Retrieves the hardware model identifier
    /// - Returns: The Mac model identifier (e.g., Mac15,11)
    func getHostModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        
        guard size > 0 else {
            return "Unknown"
        }
        
        var model = [CChar](repeating: 0, count: size)
        let result = sysctlbyname("hw.model", &model, &size, nil, 0)
        
        if result == 0 {
            return String(cString: model).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "Unknown"
        }
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
    
    /// Retrieves the kernel version
    /// - Returns: The kernel version string
    func getKernel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let kernel = withUnsafePointer(to: &systemInfo.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return kernel.isEmpty ? "Unknown" : kernel
    }
    
    /// Retrieves the system uptime
    /// - Returns: The uptime formatted as "X days, Y hours, Z mins"
    func getUptime() -> String {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        
        let result = sysctl(&mib, u_int(mib.count), &boottime, &size, nil, 0)
        
        guard result == 0 else {
            return "Unknown"
        }
        
        let bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec))
        let uptime = Date().timeIntervalSince(bootDate)
        
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        
        var components: [String] = []
        if days > 0 {
            components.append("\(days) day\(days == 1 ? "" : "s")")
        }
        if hours > 0 {
            components.append("\(hours) hour\(hours == 1 ? "" : "s")")
        }
        if minutes > 0 || components.isEmpty {
            components.append("\(minutes) min\(minutes == 1 ? "" : "s")")
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Retrieves the count of installed Homebrew packages
    /// - Returns: The package count in "N (brew)" format
    func getPackages() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "brew list --formula 2>/dev/null | wc -l"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let count = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if let packageCount = Int(count), packageCount > 0 {
                    return "\(packageCount) (brew)"
                }
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    /// Retrieves the shell name and version
    /// - Returns: The shell name and version string
    func getShell() -> String {
        guard let shellPath = ProcessInfo.processInfo.environment["SHELL"] else {
            return "Unknown"
        }
        
        let shellName = URL(fileURLWithPath: shellPath).lastPathComponent
        
        // Try to get version
        let process = Process()
        process.executableURL = URL(fileURLWithPath: shellPath)
        process.arguments = ["--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse version from first line
                let firstLine = output.components(separatedBy: .newlines).first ?? ""
                
                // Try to extract version number (common patterns)
                if let versionRange = firstLine.range(of: #"\d+\.\d+(\.\d+)?"#, options: .regularExpression) {
                    let version = String(firstLine[versionRange])
                    return "\(shellName) \(version)"
                }
            }
        } catch {
            return shellName
        }
        
        return shellName
    }
    
    /// Retrieves the screen resolution
    /// - Returns: The resolution formatted as "WIDTHxHEIGHT"
    func getResolution() -> String {
        guard let mainDisplay = CGDisplayBounds(CGMainDisplayID()) as CGRect? else {
            return "Unknown"
        }
        
        let width = Int(mainDisplay.width)
        let height = Int(mainDisplay.height)
        
        return "\(width)x\(height)"
    }
    
    /// Retrieves the desktop environment
    /// - Returns: The desktop environment name (Aqua for macOS)
    func getDE() -> String {
        return "Aqua"
    }
    
    /// Retrieves the window manager
    /// - Returns: The window manager name (Quartz Compositor for macOS)
    func getWM() -> String {
        return "Quartz Compositor"
    }
    
    /// Retrieves the window manager theme
    /// - Returns: The theme formatted as "Blue (Light)" or "Blue (Dark)"
    func getWMTheme() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "-g", "AppleInterfaceStyle"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let theme = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if theme.lowercased() == "dark" {
                    return "Blue (Dark)"
                }
            }
        } catch {
            // If the key doesn't exist, it means Light mode
            return "Blue (Light)"
        }
        
        return "Blue (Light)"
    }
    
    /// Retrieves the terminal application name
    /// - Returns: The terminal application name
    func getTerminal() -> String {
        // Try TERM_PROGRAM environment variable first
        if let termProgram = ProcessInfo.processInfo.environment["TERM_PROGRAM"] {
            return termProgram
        }
        
        // Fallback: try to get parent process name
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(getppid())", "-o", "comm="]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let terminalName = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if !terminalName.isEmpty {
                    return URL(fileURLWithPath: terminalName).lastPathComponent
                }
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    /// Retrieves the terminal font information
    /// - Returns: The terminal font name and size, or "Unknown" if not detectable
    func getTerminalFont() -> String {
        // Check for terminal-specific environment variables
        let env = ProcessInfo.processInfo.environment
        
        // iTerm2 specific
        if let font = env["ITERM_PROFILE"] {
            return font
        }
        
        // Most terminals don't expose font info via environment variables
        // This would require terminal-specific APIs or AppleScript
        return "Unknown"
    }
    
    /// Retrieves the GPU model information
    /// - Returns: The GPU model name
    func getGPUModel() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPDisplaysDataType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse GPU model from output
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("Chipset Model:") || line.contains("Graphics:") {
                        let components = line.components(separatedBy: ":")
                        if components.count > 1 {
                            let gpuModel = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            if !gpuModel.isEmpty {
                                return gpuModel
                            }
                        }
                    }
                }
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    /// Retrieves memory usage information
    /// - Returns: A tuple containing used and total memory in MiB
    func getMemoryInfo() -> (used: String, total: String) {
        // Get total memory using sysctl
        var size = MemoryLayout<UInt64>.size
        var totalMemory: UInt64 = 0
        var mib: [Int32] = [CTL_HW, HW_MEMSIZE]
        
        let result = sysctl(&mib, u_int(mib.count), &totalMemory, &size, nil, 0)
        
        guard result == 0 else {
            return (used: "Unknown", total: "Unknown")
        }
        
        let totalMiB = totalMemory / (1024 * 1024)
        
        // Get memory statistics using vm_stat
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                var pageSize: UInt64 = 4096 // Default page size
                var pagesActive: UInt64 = 0
                var pagesWired: UInt64 = 0
                var pagesCompressed: UInt64 = 0
                
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("page size of") {
                        let components = line.components(separatedBy: " ")
                        if let pageSizeIndex = components.firstIndex(of: "of"),
                           pageSizeIndex + 1 < components.count,
                           let size = UInt64(components[pageSizeIndex + 1]) {
                            pageSize = size
                        }
                    } else if line.contains("Pages active:") {
                        pagesActive = extractPageCount(from: line)
                    } else if line.contains("Pages wired down:") {
                        pagesWired = extractPageCount(from: line)
                    } else if line.contains("Pages occupied by compressor:") {
                        pagesCompressed = extractPageCount(from: line)
                    }
                }
                
                let usedBytes = (pagesActive + pagesWired + pagesCompressed) * pageSize
                let usedMiB = usedBytes / (1024 * 1024)
                
                return (used: "\(usedMiB)", total: "\(totalMiB)")
            }
        } catch {
            return (used: "Unknown", total: "\(totalMiB)")
        }
        
        return (used: "Unknown", total: "\(totalMiB)")
    }
    
    /// Helper function to extract page count from vm_stat output line
    /// - Parameter line: A line from vm_stat output
    /// - Returns: The page count as UInt64
    private func extractPageCount(from line: String) -> UInt64 {
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if let lastComponent = components.last {
            // Remove trailing period if present
            let cleaned = lastComponent.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            return UInt64(cleaned) ?? 0
        }
        return 0
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
        let hostModel = getHostModel()
        let hostname = getHostname()
        let username = getUsername()
        let kernel = getKernel()
        let uptime = getUptime()
        let packages = getPackages()
        let shell = getShell()
        let resolution = getResolution()
        let de = getDE()
        let wm = getWM()
        let wmTheme = getWMTheme()
        let terminal = getTerminal()
        let terminalFont = getTerminalFont()
        let cpuModel = getCPUModel()
        let gpuModel = getGPUModel()
        let memoryInfo = getMemoryInfo()
        
        // Apply fallback values if any field is empty
        return SystemInfo(
            osName: osInfo.name.isEmpty ? "Unknown" : osInfo.name,
            osVersion: osInfo.version.isEmpty ? "Unknown" : osInfo.version,
            osBuild: osInfo.build.isEmpty ? "Unknown" : osInfo.build,
            architecture: osInfo.architecture.isEmpty ? "Unknown" : osInfo.architecture,
            hostModel: hostModel.isEmpty ? "Unknown" : hostModel,
            hostname: hostname.isEmpty ? "Unknown" : hostname,
            username: username.isEmpty ? "Unknown" : username,
            kernel: kernel.isEmpty ? "Unknown" : kernel,
            uptime: uptime.isEmpty ? "Unknown" : uptime,
            packages: packages.isEmpty ? "Unknown" : packages,
            shell: shell.isEmpty ? "Unknown" : shell,
            resolution: resolution.isEmpty ? "Unknown" : resolution,
            de: de.isEmpty ? "Unknown" : de,
            wm: wm.isEmpty ? "Unknown" : wm,
            wmTheme: wmTheme.isEmpty ? "Unknown" : wmTheme,
            terminal: terminal.isEmpty ? "Unknown" : terminal,
            terminalFont: terminalFont.isEmpty ? "Unknown" : terminalFont,
            cpuModel: cpuModel.isEmpty ? "Unknown" : cpuModel,
            gpuModel: gpuModel.isEmpty ? "Unknown" : gpuModel,
            memoryUsed: memoryInfo.used.isEmpty ? "Unknown" : memoryInfo.used,
            memoryTotal: memoryInfo.total.isEmpty ? "Unknown" : memoryInfo.total
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
        
        // Format system information lines organized in logical groupings
        var infoLines: [String] = []
        
        // OS Information
        infoLines.append(colorFormatter.formatInfoLine("OS", "\(systemInfo.osName) \(systemInfo.osVersion) \(systemInfo.osBuild) \(systemInfo.architecture)"))
        infoLines.append(colorFormatter.formatInfoLine("Host", systemInfo.hostModel))
        infoLines.append(colorFormatter.formatInfoLine("Kernel", systemInfo.kernel))
        infoLines.append(colorFormatter.formatInfoLine("Uptime", systemInfo.uptime))
        infoLines.append(colorFormatter.formatInfoLine("Packages", systemInfo.packages))
        infoLines.append(colorFormatter.formatInfoLine("Shell", systemInfo.shell))
        
        // User Information
        infoLines.append(colorFormatter.formatInfoLine("Hostname", systemInfo.hostname))
        infoLines.append(colorFormatter.formatInfoLine("User", systemInfo.username))
        
        // Display Configuration
        infoLines.append(colorFormatter.formatInfoLine("Resolution", systemInfo.resolution))
        infoLines.append(colorFormatter.formatInfoLine("DE", systemInfo.de))
        infoLines.append(colorFormatter.formatInfoLine("WM", systemInfo.wm))
        infoLines.append(colorFormatter.formatInfoLine("WM Theme", systemInfo.wmTheme))
        
        // Terminal Environment
        infoLines.append(colorFormatter.formatInfoLine("Terminal", systemInfo.terminal))
        infoLines.append(colorFormatter.formatInfoLine("Terminal Font", systemInfo.terminalFont))
        
        // Hardware Resources
        infoLines.append(colorFormatter.formatInfoLine("CPU", systemInfo.cpuModel))
        infoLines.append(colorFormatter.formatInfoLine("GPU", systemInfo.gpuModel))
        infoLines.append(colorFormatter.formatInfoLine("Memory", "\(systemInfo.memoryUsed) MiB / \(systemInfo.memoryTotal) MiB"))
        
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
