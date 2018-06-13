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
        return try !shellOut(to: "which", arguments: [program]).isEmpty
    }
    
    static func brewInstall(_ packageName: String, options: [String] = []) throws {
        if try !Command.which("brew") {
            try Command.installHomebrew()
        }
        
        let process = Process()
        process.launchPath = "/usr/local/bin/brew"
        process.arguments = ["install", packageName] + options
        try process.launchWithOutput()
    }
    
    private static func installHomebrew() throws {
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
        let outputQueue = DispatchQueue(label: "bash-output-queue")
        
        var outputData = Data()
        var errorData = Data()
        
        let outputPipe = Pipe()
        standardOutput = outputPipe
        
        let errorPipe = Pipe()
        standardError = errorPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            outputQueue.async {
                let data = handler.availableData
                outputData.append(data)
                outputHandle?.write(data)
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            outputQueue.async {
                let data = handler.availableData
                errorData.append(data)
                errorHandle?.write(data)
            }
        }
        
        launch()
        waitUntilExit()
        
        outputHandle?.closeFile()
        errorHandle?.closeFile()
        
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        
        // Block until all writes have occurred to outputData and errorData,
        // and then read the data back out.
        return try outputQueue.sync {
            if terminationStatus != 0 {
                throw ShellOutError(
                    terminationStatus: terminationStatus,
                    errorData: errorData,
                    outputData: outputData
                )
            }
            
            return outputData.shellOutput()
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
