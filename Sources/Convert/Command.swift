//
//  Run.swift
//  Convert
//
//  Created by Mark Lowell on 6/12/18.
//  Copyright © 2018 Mark Malstrom. All rights reserved.
//

import Foundation

struct Command {
    enum Executable: String {
        case ffprobe = "/usr/local/bin/ffprobe"
        case ffmpeg = "/usr/local/bin/ffmpeg"
        case trash = "/usr/local/bin/trash"
    }
    
    @discardableResult
    static func run(_ executable: Executable, arguments: [String]) throws -> String {
        let process = Process()
        process.launchPath = executable.rawValue
        process.arguments = arguments
        return try process.launchWithOutput()
    }

    @discardableResult
    static func run(_ executable: Executable, arguments: String) throws -> String {
        return try Command.run(executable, arguments: [arguments])
    }
    
    static func which(_ program: String) throws -> Bool {
        // True if program exists, false if not
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = [program]
        process.environment = ProcessInfo.processInfo.environment
        return try !process.launchWithOutput().isEmpty
    }
    
    static func brewInstall(_ packageName: String, options: [String] = []) throws {
        if try !Command.which("brew") {
            try Command.installHomebrew()
        }

        print("Installing \(packageName)...")
        
        let process = Process()
        process.launchPath = "/usr/local/bin/brew"
        process.arguments = ["install", packageName] + options
        try process.launchWithOutput()
    }
    
    private static func installHomebrew() throws {
        print("Installing homebrew...")
        let process = Process()
        process.launchPath = "/usr/bin/ruby"
        process.arguments = [
            "-e",
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)".encapsulated()
        ]
        try process.launchWithOutput()
    }
}

private extension Process {
    @discardableResult
    func launchWithOutput(outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil) throws -> String {
        
        let outputPipe = Pipe()
        standardOutput = outputPipe
        
        let errorPipe = Pipe()
        standardError = errorPipe
        
        self.launch()

        self.waitUntilExit()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        switch self.terminationStatus {
        case 0: return outputData.shellOutput()
        case 1: return ""
        default:
            let errorMessage = errorData.shellOutput()

            if errorMessage.contains("No such file or directory") {
                throw Converter.Error.noSuchFileOrDirectory
            } else {
                throw Converter.Error.unknownError(
                    stderr: errorMessage,
                    statusCode: Int(terminationStatus)
                )
            }
        }
    }
}

private extension Data {
    func shellOutput() -> String {
        guard let output = String(data: self, encoding: .utf8) else {
            return ""
        }
        
        guard !output.hasSuffix("\n") else {
            let endIndex = output.index(before: output.endIndex)
            return String(output[..<endIndex])
        }
        
        return output
        
    }
}
