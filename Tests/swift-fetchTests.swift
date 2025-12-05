import XCTest
import SwiftCheck
@testable import swift_fetch

final class SwiftFetchTests: XCTestCase {
    // Test cases will be added in later tasks
    
    func testPlaceholder() {
        // Placeholder test to verify test setup
        XCTAssertTrue(true)
    }
    
    /// **Feature: swift-fetch, Property 1: Comprehensive system information completeness**
    /// **Validates: Requirements 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 4.1**
    ///
    /// Property: For any execution of the system info collector on macOS, all required fields
    /// (OS name, OS version, OS build, architecture, host model, hostname, username, kernel,
    /// uptime, packages, shell, resolution, DE, WM, WM theme, terminal, terminal font, CPU model,
    /// GPU model, memory used, memory total) should be populated with non-empty values or
    /// appropriate fallback values.
    func testComprehensiveSystemInformationCompleteness() {
        // Property-based test: Run 25 iterations to verify system info collection
        // always returns complete data
        let args = CheckerArguments(replay: nil, maxAllowableSuccessfulTests: 25, maxTestCaseSize: 25)
        
        property("All system information fields are non-empty", arguments: args) <- forAll { (_: Int) in
            // Collect system information
            let collector = SystemInfoCollector()
            let systemInfo = collector.collect()
            
            // Verify all fields are non-empty (either real data or fallback values like "Unknown")
            let allFieldsNonEmpty = 
                !systemInfo.osName.isEmpty &&
                !systemInfo.osVersion.isEmpty &&
                !systemInfo.osBuild.isEmpty &&
                !systemInfo.architecture.isEmpty &&
                !systemInfo.hostModel.isEmpty &&
                !systemInfo.hostname.isEmpty &&
                !systemInfo.username.isEmpty &&
                !systemInfo.kernel.isEmpty &&
                !systemInfo.uptime.isEmpty &&
                !systemInfo.packages.isEmpty &&
                !systemInfo.shell.isEmpty &&
                !systemInfo.resolution.isEmpty &&
                !systemInfo.de.isEmpty &&
                !systemInfo.wm.isEmpty &&
                !systemInfo.wmTheme.isEmpty &&
                !systemInfo.terminal.isEmpty &&
                !systemInfo.terminalFont.isEmpty &&
                !systemInfo.cpuModel.isEmpty &&
                !systemInfo.gpuModel.isEmpty &&
                !systemInfo.memoryUsed.isEmpty &&
                !systemInfo.memoryTotal.isEmpty
            
            return allFieldsNonEmpty
        }
    }
    
    /// **Feature: swift-fetch, Property 2: Color code application**
    /// **Validates: Requirements 2.1, 2.3, 3.3**
    ///
    /// Property: For any text string that is colorized, the output should contain valid ANSI
    /// escape sequences that match the standard format \u{001B}[<code>m.
    func testColorCodeApplication() {
        // Property-based test: Run 25 iterations to verify color code application
        let args = CheckerArguments(replay: nil, maxAllowableSuccessfulTests: 25, maxTestCaseSize: 25)
        
        property("Colorized text contains valid ANSI escape sequences", arguments: args) <- forAll { (text: String) in
            let formatter = ColorFormatter()
            
            // Test all available colors
            let colors: [ANSIColor] = [.red, .green, .yellow, .blue, .magenta, .cyan, .white, .boldCyan, .brightGreen, .brightYellow, .brightRed, .brightMagenta, .orange]
            
            // For each color, verify the colorized output contains valid ANSI codes
            return colors.allSatisfy { color in
                let colorized = formatter.colorize(text, color: color)
                
                // Check that the output contains the color's ANSI escape sequence
                let containsColorCode = colorized.contains(color.rawValue)
                
                // Check that the output contains the reset code
                let containsResetCode = colorized.contains(ANSIColor.reset.rawValue)
                
                // Verify the ANSI escape sequence format using regex pattern
                // Pattern: \u{001B}[<digits and semicolons>m
                let ansiPattern = "\u{001B}\\[[0-9;]+m"
                let hasValidFormat = colorized.range(of: ansiPattern, options: .regularExpression) != nil
                
                return containsColorCode && containsResetCode && hasValidFormat
            }
        }
    }
    
    /// **Feature: swift-fetch, Property 3: Color reset prevents bleeding**
    /// **Validates: Requirements 2.4**
    ///
    /// Property: For any text string that is colorized, the output should end with the ANSI
    /// reset code \u{001B}[0m to prevent color bleeding.
    func testColorResetPreventsbleeding() {
        // Property-based test: Run 25 iterations to verify color reset
        let args = CheckerArguments(replay: nil, maxAllowableSuccessfulTests: 25, maxTestCaseSize: 25)
        
        property("Colorized text ends with ANSI reset code", arguments: args) <- forAll { (text: String) in
            let formatter = ColorFormatter()
            
            // Test all available colors
            let colors: [ANSIColor] = [.red, .green, .yellow, .blue, .magenta, .cyan, .white, .boldCyan, .brightGreen, .brightYellow, .brightRed, .brightMagenta, .orange]
            
            // For each color, verify the colorized output ends with reset code
            return colors.allSatisfy { color in
                let colorized = formatter.colorize(text, color: color)
                
                // Verify the output ends with the reset code
                let endsWithReset = colorized.hasSuffix(ANSIColor.reset.rawValue)
                
                return endsWithReset
            }
        }
    }
    
    /// **Feature: swift-fetch, Property 4: Label and value color distinction**
    /// **Validates: Requirements 2.2**
    ///
    /// Property: For any label-value pair formatted for display, the label color code should
    /// differ from the value color code.
    func testLabelAndValueColorDistinction() {
        // Property-based test: Run 25 iterations to verify label and value color distinction
        let args = CheckerArguments(replay: nil, maxAllowableSuccessfulTests: 25, maxTestCaseSize: 25)
        
        property("Label and value have distinct color codes", arguments: args) <- forAll { (label: String, value: String) in
            let formatter = ColorFormatter()
            
            // Format the info line
            let formattedLine = formatter.formatInfoLine(label, value)
            
            // Extract the label color code (should be boldCyan)
            let labelColorCode = ANSIColor.boldCyan.rawValue
            
            // Extract the value color code (should be white)
            let valueColorCode = ANSIColor.white.rawValue
            
            // Verify both color codes are present in the formatted line
            let containsLabelColor = formattedLine.contains(labelColorCode)
            let containsValueColor = formattedLine.contains(valueColorCode)
            
            // Verify the color codes are different
            let colorsAreDifferent = labelColorCode != valueColorCode
            
            return containsLabelColor && containsValueColor && colorsAreDifferent
        }
    }
    
    /// **Feature: swift-fetch, Property 7: Fallback on retrieval errors**
    /// **Validates: Requirements 4.3**
    ///
    /// Property: For any system information field that fails to retrieve, the collector should
    /// return a non-empty fallback value (e.g., "Unknown") instead of an empty string or throwing an error.
    func testFallbackOnRetrievalErrors() {
        // Property-based test: Run 25 iterations to verify fallback behavior
        let args = CheckerArguments(replay: nil, maxAllowableSuccessfulTests: 25, maxTestCaseSize: 25)
        
        property("Empty retrieval results are replaced with fallback values", arguments: args) <- forAll { (_: Int) in
            // Create a test collector that simulates retrieval failures
            let collector = FailingSystemInfoCollector()
            let systemInfo = collector.collect()
            
            // Verify that even with simulated failures, all fields have non-empty fallback values
            let allFieldsHaveFallbacks = 
                !systemInfo.osName.isEmpty &&
                !systemInfo.osVersion.isEmpty &&
                !systemInfo.osBuild.isEmpty &&
                !systemInfo.architecture.isEmpty &&
                !systemInfo.hostModel.isEmpty &&
                !systemInfo.hostname.isEmpty &&
                !systemInfo.username.isEmpty &&
                !systemInfo.kernel.isEmpty &&
                !systemInfo.uptime.isEmpty &&
                !systemInfo.packages.isEmpty &&
                !systemInfo.shell.isEmpty &&
                !systemInfo.resolution.isEmpty &&
                !systemInfo.de.isEmpty &&
                !systemInfo.wm.isEmpty &&
                !systemInfo.wmTheme.isEmpty &&
                !systemInfo.terminal.isEmpty &&
                !systemInfo.terminalFont.isEmpty &&
                !systemInfo.cpuModel.isEmpty &&
                !systemInfo.gpuModel.isEmpty &&
                !systemInfo.memoryUsed.isEmpty &&
                !systemInfo.memoryTotal.isEmpty
            
            return allFieldsHaveFallbacks
        }
    }
    
    /// **Feature: swift-fetch, Property 5: Information formatting consistency**
    /// **Validates: Requirements 6.1, 6.2**
    ///
    /// Property: For any set of label-value pairs formatted for display, all pairs should have
    /// consistent spacing between labels and values, and all lines should be properly aligned.
    func testInformationFormattingConsistency() {
        // Property-based test: Run 25 iterations to verify formatting consistency
        let args = CheckerArguments(replay: nil, maxAllowableSuccessfulTests: 25, maxTestCaseSize: 25)
        
        property("All label-value pairs have consistent formatting", arguments: args) <- forAll { (label1: String, value1: String, label2: String, value2: String, label3: String, value3: String) in
            let formatter = ColorFormatter()
            
            // Format multiple label-value pairs
            let pairs = [(label1, value1), (label2, value2), (label3, value3)]
            let formattedLines = pairs.map { (label, value) in
                formatter.formatInfoLine(label, value)
            }
            
            // Helper function to strip ANSI codes for analysis
            func stripANSICodes(_ text: String) -> String {
                let pattern = "\u{001B}\\[[0-9;]*m"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    return text
                }
                let range = NSRange(text.startIndex..., in: text)
                return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            }
            
            // Check 1: All lines should contain the separator ": " between label and value
            let allHaveSeparator = formattedLines.allSatisfy { line in
                let stripped = stripANSICodes(line)
                return stripped.contains(": ")
            }
            
            // Check 2: The separator should appear exactly once in each line
            let separatorCountConsistent = formattedLines.allSatisfy { line in
                let stripped = stripANSICodes(line)
                let separatorCount = stripped.components(separatedBy: ": ").count - 1
                return separatorCount == 1
            }
            
            // Check 3: Each line should have the same structure: label + ": " + value
            // We verify this by checking that splitting on ": " produces exactly 2 parts
            let structureConsistent = formattedLines.allSatisfy { line in
                let stripped = stripANSICodes(line)
                let parts = stripped.components(separatedBy: ": ")
                return parts.count == 2
            }
            
            // Check 4: All lines should use the same color codes for labels and values
            // Extract the first color code (label color) and last color code before reset (value color)
            let colorCodesConsistent = formattedLines.allSatisfy { line in
                // Should contain bold cyan for label
                let hasLabelColor = line.contains(ANSIColor.boldCyan.rawValue)
                // Should contain white for value
                let hasValueColor = line.contains(ANSIColor.white.rawValue)
                // Should end with reset
                let endsWithReset = line.hasSuffix(ANSIColor.reset.rawValue)
                
                return hasLabelColor && hasValueColor && endsWithReset
            }
            
            return allHaveSeparator && separatorCountConsistent && structureConsistent && colorCodesConsistent
        }
    }
    
    // MARK: - Unit Tests for ASCII Art Provider
    
    /// Unit test: Verify getMacOSArt() returns a non-empty array
    /// _Requirements: 3.3, 3.4_
    func testGetMacOSArtReturnsNonEmptyArray() {
        let artProvider = ASCIIArtProvider()
        let art = artProvider.getMacOSArt()
        
        // Verify the art array is not empty
        XCTAssertFalse(art.isEmpty, "getMacOSArt() should return a non-empty array")
        
        // Verify each line is a non-empty string
        for (index, line) in art.enumerated() {
            XCTAssertFalse(line.isEmpty, "Art line at index \(index) should not be empty")
        }
    }
    
    /// Unit test: Verify colorizeArt() applies colors to all lines
    /// _Requirements: 3.3, 3.4_
    func testColorizeArtAppliesColorsToAllLines() {
        let artProvider = ASCIIArtProvider()
        let art = artProvider.getMacOSArt()
        
        // Test with different colors
        let testColors: [ANSIColor] = [.red, .green, .blue, .cyan, .magenta, .yellow]
        
        for color in testColors {
            let colorizedArt = artProvider.colorizeArt(art, color: color)
            
            // Verify the colorized art has the same number of lines as the original
            XCTAssertEqual(colorizedArt.count, art.count, "Colorized art should have the same number of lines as original art")
            
            // Verify each line has been colorized
            for (index, colorizedLine) in colorizedArt.enumerated() {
                // Check that the line contains the color code
                XCTAssertTrue(colorizedLine.contains(color.rawValue), 
                             "Line \(index) should contain the color code for \(color)")
                
                // Check that the line contains the reset code
                XCTAssertTrue(colorizedLine.contains(ANSIColor.reset.rawValue), 
                             "Line \(index) should contain the reset code")
                
                // Check that the line ends with the reset code
                XCTAssertTrue(colorizedLine.hasSuffix(ANSIColor.reset.rawValue), 
                             "Line \(index) should end with the reset code")
                
                // Check that the original art content is preserved
                let originalLine = art[index]
                XCTAssertTrue(colorizedLine.contains(originalLine), 
                             "Line \(index) should contain the original art content")
            }
        }
    }
    
    // MARK: - Unit Tests for Display Renderer
    
    /// Unit test: Verify combineArtAndInfo() alignment logic with more info lines than art lines
    /// _Requirements: 3.2, 6.3_
    func testCombineArtAndInfoWithMoreInfoLines() {
        let artProvider = ASCIIArtProvider()
        let colorFormatter = ColorFormatter()
        let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)
        
        // Create simple test art (3 lines)
        let art = ["Line 1", "Line 2", "Line 3"]
        
        // Create more info lines than art lines (5 lines)
        let info = [
            "Info 1",
            "Info 2",
            "Info 3",
            "Info 4",
            "Info 5"
        ]
        
        // Combine art and info
        let combined = renderer.combineArtAndInfo(art: art, info: info)
        
        // Helper function to strip ANSI codes
        func stripANSICodes(_ text: String) -> String {
            let pattern = "\u{001B}\\[[0-9;]*m"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // Verify the combined output has the correct number of lines (max of art and info)
        XCTAssertEqual(combined.count, 5, "Combined output should have 5 lines (max of art and info)")
        
        // Verify first 3 lines contain both art and info
        for i in 0..<3 {
            let strippedLine = stripANSICodes(combined[i])
            XCTAssertTrue(strippedLine.contains(art[i]), "Line \(i) should contain art content")
            XCTAssertTrue(strippedLine.contains(info[i]), "Line \(i) should contain info content")
        }
        
        // Verify last 2 lines contain only info (with proper spacing)
        for i in 3..<5 {
            let strippedLine = stripANSICodes(combined[i])
            XCTAssertTrue(strippedLine.contains(info[i]), "Line \(i) should contain info content")
            
            // Verify proper spacing before info (should have artWidth + padding spaces)
            let artWidth = art.map { $0.count }.max() ?? 0
            let padding = 4
            let expectedSpaces = artWidth + padding
            let leadingSpaces = strippedLine.prefix(while: { $0 == " " }).count
            XCTAssertGreaterThanOrEqual(leadingSpaces, expectedSpaces, 
                                       "Line \(i) should have at least \(expectedSpaces) leading spaces")
        }
        
        // Verify consistent alignment - all info should start at the same column
        let artWidth = art.map { $0.count }.max() ?? 0
        let padding = 4
        let expectedInfoColumn = artWidth + padding
        
        for i in 0..<combined.count {
            let strippedLine = stripANSICodes(combined[i])
            if let infoRange = strippedLine.range(of: info[i]) {
                let infoStartColumn = strippedLine.distance(from: strippedLine.startIndex, to: infoRange.lowerBound)
                XCTAssertEqual(infoStartColumn, expectedInfoColumn, 
                              "Info on line \(i) should start at column \(expectedInfoColumn)")
            } else {
                XCTFail("Line \(i) should contain info content")
            }
        }
    }
    
    /// Unit test: Verify combineArtAndInfo() alignment logic with more art lines than info lines
    /// _Requirements: 3.2, 6.3_
    func testCombineArtAndInfoWithMoreArtLines() {
        let artProvider = ASCIIArtProvider()
        let colorFormatter = ColorFormatter()
        let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)
        
        // Create test art with more lines (5 lines)
        let art = ["Art 1", "Art 2", "Art 3", "Art 4", "Art 5"]
        
        // Create fewer info lines (3 lines)
        let info = ["Info 1", "Info 2", "Info 3"]
        
        // Combine art and info
        let combined = renderer.combineArtAndInfo(art: art, info: info)
        
        // Helper function to strip ANSI codes
        func stripANSICodes(_ text: String) -> String {
            let pattern = "\u{001B}\\[[0-9;]*m"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // Verify the combined output has the correct number of lines (max of art and info)
        XCTAssertEqual(combined.count, 5, "Combined output should have 5 lines (max of art and info)")
        
        // Verify first 3 lines contain both art and info
        for i in 0..<3 {
            let strippedLine = stripANSICodes(combined[i])
            XCTAssertTrue(strippedLine.contains(art[i]), "Line \(i) should contain art content")
            XCTAssertTrue(strippedLine.contains(info[i]), "Line \(i) should contain info content")
        }
        
        // Verify last 2 lines contain only art (no info)
        for i in 3..<5 {
            let strippedLine = stripANSICodes(combined[i])
            XCTAssertTrue(strippedLine.contains(art[i]), "Line \(i) should contain art content")
            
            // Verify no info content on these lines (just art + padding)
            for infoLine in info {
                XCTAssertFalse(strippedLine.contains(infoLine), 
                              "Line \(i) should not contain any info content")
            }
        }
    }
    
    /// Unit test: Verify combineArtAndInfo() handles equal line counts correctly
    /// _Requirements: 3.2, 6.3_
    func testCombineArtAndInfoWithEqualLineCounts() {
        let artProvider = ASCIIArtProvider()
        let colorFormatter = ColorFormatter()
        let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)
        
        // Create art and info with equal line counts (4 lines each)
        let art = ["Art Line 1", "Art Line 2", "Art Line 3", "Art Line 4"]
        let info = ["Info 1", "Info 2", "Info 3", "Info 4"]
        
        // Combine art and info
        let combined = renderer.combineArtAndInfo(art: art, info: info)
        
        // Helper function to strip ANSI codes
        func stripANSICodes(_ text: String) -> String {
            let pattern = "\u{001B}\\[[0-9;]*m"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // Verify the combined output has the correct number of lines
        XCTAssertEqual(combined.count, 4, "Combined output should have 4 lines")
        
        // Verify all lines contain both art and info
        for i in 0..<4 {
            let strippedLine = stripANSICodes(combined[i])
            XCTAssertTrue(strippedLine.contains(art[i]), "Line \(i) should contain art content")
            XCTAssertTrue(strippedLine.contains(info[i]), "Line \(i) should contain info content")
        }
        
        // Verify consistent spacing between art and info
        let padding = 4
        
        for i in 0..<combined.count {
            let strippedLine = stripANSICodes(combined[i])
            let artLine = art[i]
            let infoLine = info[i]
            
            // Find where art ends and info begins
            if let artRange = strippedLine.range(of: artLine),
               let infoRange = strippedLine.range(of: infoLine) {
                let artEnd = strippedLine.distance(from: strippedLine.startIndex, to: artRange.upperBound)
                let infoStart = strippedLine.distance(from: strippedLine.startIndex, to: infoRange.lowerBound)
                
                // Calculate spacing between art and info
                let spacingBetween = infoStart - artEnd
                
                // Verify spacing is at least the padding amount
                XCTAssertGreaterThanOrEqual(spacingBetween, padding, 
                                           "Line \(i) should have at least \(padding) spaces between art and info")
            } else {
                XCTFail("Line \(i) should contain both art and info content")
            }
        }
    }
    
    /// Unit test: Verify combineArtAndInfo() handles empty art array
    /// _Requirements: 3.2, 6.3_
    func testCombineArtAndInfoWithEmptyArt() {
        let artProvider = ASCIIArtProvider()
        let colorFormatter = ColorFormatter()
        let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)
        
        // Create empty art array
        let art: [String] = []
        
        // Create info lines
        let info = ["Info 1", "Info 2", "Info 3"]
        
        // Combine art and info
        let combined = renderer.combineArtAndInfo(art: art, info: info)
        
        // Helper function to strip ANSI codes
        func stripANSICodes(_ text: String) -> String {
            let pattern = "\u{001B}\\[[0-9;]*m"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // Verify the combined output has the correct number of lines (same as info)
        XCTAssertEqual(combined.count, 3, "Combined output should have 3 lines (same as info)")
        
        // Verify all lines contain only info with proper spacing
        for i in 0..<combined.count {
            let strippedLine = stripANSICodes(combined[i])
            XCTAssertTrue(strippedLine.contains(info[i]), "Line \(i) should contain info content")
            
            // Verify proper leading spacing (artWidth is 0, so just padding)
            let padding = 4
            let leadingSpaces = strippedLine.prefix(while: { $0 == " " }).count
            XCTAssertGreaterThanOrEqual(leadingSpaces, padding, 
                                       "Line \(i) should have at least \(padding) leading spaces")
        }
    }
    
    /// Unit test: Verify combineArtAndInfo() handles empty info array
    /// _Requirements: 3.2, 6.3_
    func testCombineArtAndInfoWithEmptyInfo() {
        let artProvider = ASCIIArtProvider()
        let colorFormatter = ColorFormatter()
        let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)
        
        // Create art lines
        let art = ["Art 1", "Art 2", "Art 3"]
        
        // Create empty info array
        let info: [String] = []
        
        // Combine art and info
        let combined = renderer.combineArtAndInfo(art: art, info: info)
        
        // Helper function to strip ANSI codes
        func stripANSICodes(_ text: String) -> String {
            let pattern = "\u{001B}\\[[0-9;]*m"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // Verify the combined output has the correct number of lines (same as art)
        XCTAssertEqual(combined.count, 3, "Combined output should have 3 lines (same as art)")
        
        // Verify all lines contain only art
        for i in 0..<combined.count {
            let strippedLine = stripANSICodes(combined[i])
            XCTAssertTrue(strippedLine.contains(art[i]), "Line \(i) should contain art content")
        }
    }
    
    // MARK: - Integration Tests
    
    /// Integration test: Verify complete tool execution produces expected output
    /// _Requirements: 1.1, 4.4_
    func testEndToEndExecution() {
        // Collect system information
        let collector = SystemInfoCollector()
        let systemInfo = collector.collect()
        
        // Verify system info is not empty
        XCTAssertFalse(systemInfo.isEmpty, "System info should not be empty")
        
        // Verify all critical fields are populated
        XCTAssertFalse(systemInfo.osName.isEmpty, "OS name should be populated")
        XCTAssertFalse(systemInfo.osVersion.isEmpty, "OS version should be populated")
        XCTAssertFalse(systemInfo.hostname.isEmpty, "Hostname should be populated")
        XCTAssertFalse(systemInfo.username.isEmpty, "Username should be populated")
        
        // Create formatter and art provider
        let colorFormatter = ColorFormatter()
        let artProvider = ASCIIArtProvider()
        
        // Get ASCII art
        let art = artProvider.getMacOSArt()
        XCTAssertFalse(art.isEmpty, "ASCII art should not be empty")
        
        // Colorize art
        let colorizedArt = artProvider.colorizeArtRainbow(art)
        XCTAssertEqual(colorizedArt.count, art.count, "Colorized art should have same number of lines as original")
        
        // Verify colorized art contains ANSI codes
        for line in colorizedArt {
            XCTAssertTrue(line.contains("\u{001B}["), "Colorized art line should contain ANSI escape codes")
            XCTAssertTrue(line.contains(ANSIColor.reset.rawValue), "Colorized art line should contain reset code")
        }
        
        // Create renderer
        let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)
        
        // Format system information lines
        var infoLines: [String] = []
        
        // Header
        let greenColor = ANSIColor.brightGreen.rawValue
        let resetColor = ANSIColor.reset.rawValue
        let userHostLine = "\(greenColor)\(systemInfo.username)\(resetColor)@\(greenColor)\(systemInfo.hostname)\(resetColor)"
        infoLines.append(userHostLine)
        infoLines.append(String(repeating: "-", count: 33))
        
        // OS Information
        infoLines.append(colorFormatter.formatInfoLine("OS", "\(systemInfo.osName) \(systemInfo.osVersion) \(systemInfo.osBuild) \(systemInfo.architecture)"))
        infoLines.append(colorFormatter.formatInfoLine("Host", systemInfo.hostModel))
        infoLines.append(colorFormatter.formatInfoLine("Kernel", systemInfo.kernel))
        infoLines.append(colorFormatter.formatInfoLine("Uptime", systemInfo.uptime))
        infoLines.append(colorFormatter.formatInfoLine("Packages", systemInfo.packages))
        infoLines.append(colorFormatter.formatInfoLine("Shell", systemInfo.shell))
        
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
        
        // Verify all info lines are formatted with colors
        for line in infoLines {
            if line != String(repeating: "-", count: 33) && !line.contains("@") {
                // Regular info lines should have color codes
                XCTAssertTrue(line.contains("\u{001B}["), "Info line should contain ANSI escape codes")
                XCTAssertTrue(line.contains(ANSIColor.reset.rawValue), "Info line should contain reset code")
            }
        }
        
        // Combine art and info
        let combined = renderer.combineArtAndInfo(art: colorizedArt, info: infoLines)
        
        // Verify combined output
        XCTAssertFalse(combined.isEmpty, "Combined output should not be empty")
        XCTAssertGreaterThanOrEqual(combined.count, art.count, "Combined output should have at least as many lines as art")
        XCTAssertGreaterThanOrEqual(combined.count, infoLines.count, "Combined output should have at least as many lines as info")
        
        // Helper function to strip ANSI codes
        func stripANSICodes(_ text: String) -> String {
            let pattern = "\u{001B}\\[[0-9;]*m"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // Verify that combined output contains both art and info content
        let combinedStripped = combined.map { stripANSICodes($0) }.joined(separator: "\n")
        
        // Check for presence of key system information fields
        XCTAssertTrue(combinedStripped.contains(systemInfo.username), "Output should contain username")
        XCTAssertTrue(combinedStripped.contains(systemInfo.hostname), "Output should contain hostname")
        XCTAssertTrue(combinedStripped.contains("OS:"), "Output should contain OS label")
        XCTAssertTrue(combinedStripped.contains("Host:"), "Output should contain Host label")
        XCTAssertTrue(combinedStripped.contains("Kernel:"), "Output should contain Kernel label")
        XCTAssertTrue(combinedStripped.contains("Uptime:"), "Output should contain Uptime label")
        XCTAssertTrue(combinedStripped.contains("Shell:"), "Output should contain Shell label")
        XCTAssertTrue(combinedStripped.contains("Resolution:"), "Output should contain Resolution label")
        XCTAssertTrue(combinedStripped.contains("DE:"), "Output should contain DE label")
        XCTAssertTrue(combinedStripped.contains("WM:"), "Output should contain WM label")
        XCTAssertTrue(combinedStripped.contains("Terminal:"), "Output should contain Terminal label")
        XCTAssertTrue(combinedStripped.contains("CPU:"), "Output should contain CPU label")
        XCTAssertTrue(combinedStripped.contains("GPU:"), "Output should contain GPU label")
        XCTAssertTrue(combinedStripped.contains("Memory:"), "Output should contain Memory label")
        
        // Check for presence of ASCII art content (check for some characteristic art characters)
        XCTAssertTrue(combinedStripped.contains("'c."), "Output should contain ASCII art content")
        XCTAssertTrue(combinedStripped.contains("xNMM"), "Output should contain ASCII art content")
        
        // Verify no errors occurred (all fields should have values, not "Unknown" for critical fields)
        XCTAssertNotEqual(systemInfo.osName, "Unknown", "OS name should be detected")
        XCTAssertNotEqual(systemInfo.hostname, "Unknown", "Hostname should be detected")
        XCTAssertNotEqual(systemInfo.username, "Unknown", "Username should be detected")
        
        // Test complete - tool executed successfully without errors
    }
    
    /// **Feature: swift-fetch, Property 6: Art and info alignment without overlap**
    /// **Validates: Requirements 3.2, 6.3**
    ///
    /// Property: For any ASCII art lines and system info lines combined for display, the resulting
    /// output should position them side-by-side with consistent spacing and no character overlap.
    func testArtAndInfoAlignmentWithoutOverlap() {
        // Property-based test: Run 25 iterations to verify art and info alignment
        let args = CheckerArguments(replay: nil, maxAllowableSuccessfulTests: 25, maxTestCaseSize: 25)
        
        property("Art and info are aligned side-by-side without overlap", arguments: args) <- forAll { (infoCount: Int) in
            // Generate a reasonable number of info lines (1-30)
            let numInfoLines = max(1, min(abs(infoCount % 30) + 1, 30))
            
            // Create test data
            let artProvider = ASCIIArtProvider()
            let colorFormatter = ColorFormatter()
            let renderer = DisplayRenderer(artProvider: artProvider, colorFormatter: colorFormatter)
            
            // Get ASCII art
            let art = artProvider.getMacOSArt()
            let colorizedArt = artProvider.colorizeArtRainbow(art)
            
            // Generate random info lines
            var infoLines: [String] = []
            for i in 0..<numInfoLines {
                let label = "Label\(i)"
                let value = "Value\(i)"
                infoLines.append(colorFormatter.formatInfoLine(label, value))
            }
            
            // Combine art and info
            let combined = renderer.combineArtAndInfo(art: colorizedArt, info: infoLines)
            
            // Helper function to strip ANSI codes
            func stripANSICodes(_ text: String) -> String {
                let pattern = "\u{001B}\\[[0-9;]*m"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    return text
                }
                let range = NSRange(text.startIndex..., in: text)
                return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            }
            
            // Property 1: Combined output should have at least as many lines as the maximum of art and info
            let maxLines = max(art.count, infoLines.count)
            guard combined.count >= maxLines else {
                return false
            }
            
            // Property 2: Each line should contain both art and info (or appropriate spacing)
            // Calculate expected art width (without ANSI codes)
            let artWidth = art.map { stripANSICodes($0).count }.max() ?? 0
            let padding = 4
            
            for (index, line) in combined.enumerated() {
                let strippedLine = stripANSICodes(line)
                
                // Property 3: Lines should be long enough to contain art + padding + info
                // At minimum, should have art width + padding
                guard strippedLine.count >= artWidth + padding else {
                    return false
                }
                
                // Property 4: Check for no overlap by verifying spacing
                // The art portion should be followed by at least 'padding' spaces before info starts
                // We verify this by checking that there's adequate spacing between art and info
                
                if index < art.count && index < infoLines.count {
                    // Both art and info exist on this line
                    let artLineStripped = stripANSICodes(art[index])
                    let infoLineStripped = stripANSICodes(infoLines[index])
                    
                    // The stripped combined line should contain both the art and info content
                    guard strippedLine.contains(artLineStripped) else {
                        return false
                    }
                    
                    // Find where the art ends in the stripped line
                    if let artRange = strippedLine.range(of: artLineStripped) {
                        let afterArtIndex = artRange.upperBound
                        let remainingText = String(strippedLine[afterArtIndex...])
                        
                        // There should be at least 'padding' spaces before info content
                        let leadingSpaces = remainingText.prefix(while: { $0 == " " }).count
                        guard leadingSpaces >= padding else {
                            return false
                        }
                        
                        // After the padding, the info should be present
                        let afterPadding = remainingText.dropFirst(leadingSpaces)
                        guard afterPadding.hasPrefix(infoLineStripped) else {
                            return false
                        }
                    } else {
                        return false
                    }
                } else if index < art.count {
                    // Only art exists on this line
                    let artLineStripped = stripANSICodes(art[index])
                    guard strippedLine.contains(artLineStripped) else {
                        return false
                    }
                } else if index < infoLines.count {
                    // Only info exists on this line (art has ended)
                    // Should have proper spacing before info
                    let infoLineStripped = stripANSICodes(infoLines[index])
                    
                    // The line should start with spaces equal to artWidth + padding
                    let expectedSpaces = artWidth + padding
                    let leadingSpaces = strippedLine.prefix(while: { $0 == " " }).count
                    
                    guard leadingSpaces >= expectedSpaces else {
                        return false
                    }
                    
                    // After the spacing, info should be present
                    let afterSpacing = strippedLine.dropFirst(leadingSpaces)
                    guard afterSpacing.hasPrefix(infoLineStripped) else {
                        return false
                    }
                }
            }
            
            // Property 5: Consistent alignment - all info lines should start at the same column
            // Calculate where info should start (artWidth + padding)
            let expectedInfoStartColumn = artWidth + padding
            
            for (index, line) in combined.enumerated() {
                if index < infoLines.count {
                    let strippedLine = stripANSICodes(line)
                    let infoLineStripped = stripANSICodes(infoLines[index])
                    
                    // Find where the info starts in the combined line
                    if let infoRange = strippedLine.range(of: infoLineStripped) {
                        let infoStartIndex = strippedLine.distance(from: strippedLine.startIndex, to: infoRange.lowerBound)
                        
                        // Info should start at the expected column
                        guard infoStartIndex == expectedInfoStartColumn else {
                            return false
                        }
                    } else {
                        return false
                    }
                }
            }
            
            return true
        }
    }
}

// MARK: - Test Helper Classes

/// A test collector that simulates retrieval failures by returning empty strings
class FailingSystemInfoCollector: SystemInfoCollector {
    
    override func getOSInfo() -> (name: String, version: String, build: String, architecture: String) {
        return (name: "", version: "", build: "", architecture: "")
    }
    
    override func getHostModel() -> String {
        return ""
    }
    
    override func getHostname() -> String {
        return ""
    }
    
    override func getUsername() -> String {
        return ""
    }
    
    override func getKernel() -> String {
        return ""
    }
    
    override func getUptime() -> String {
        return ""
    }
    
    override func getPackages() -> String {
        return ""
    }
    
    override func getShell() -> String {
        return ""
    }
    
    override func getResolution() -> String {
        return ""
    }
    
    override func getDE() -> String {
        return ""
    }
    
    override func getWM() -> String {
        return ""
    }
    
    override func getWMTheme() -> String {
        return ""
    }
    
    override func getTerminal() -> String {
        return ""
    }
    
    override func getTerminalFont() -> String {
        return ""
    }
    
    override func getCPUModel() -> String {
        return ""
    }
    
    override func getGPUModel() -> String {
        return ""
    }
    
    override func getMemoryInfo() -> (used: String, total: String) {
        return (used: "", total: "")
    }
}
