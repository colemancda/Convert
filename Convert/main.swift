//
//  main.swift
//  Convert
//
//  Created by Mark Lowell on 6/6/18.
//  Copyright © 2018 Mark Malstrom. All rights reserved.
//

import Foundation

func installDependencies() throws {
    if try shellOut(to: "which", arguments: ["brew"]).isEmpty {
        // Install Homebrew
        try shellOut(to: "/usr/bin/ruby", arguments: [
            "-e",
            "\"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
        ])
        // Update outdated macOS packages
        try shellOut(to: "brew", arguments: ["install", "bash"])
    }
    
    // FFmpeg
    if try shellOut(to: "which", arguments: ["ffmpeg"]).isEmpty {
        try shellOut(to: "brew", arguments: ["install", "ffmpeg", "--with-x265", "--with-fdk-aac", "--HEAD"])
    }
    
    // Trash
    if try shellOut(to: "which", arguments: ["trash"]).isEmpty {
        try shellOut(to: "brew", arguments: ["install", "trash"])
    }
}

// try installDependencies()
try Converter.convert(path: CommandLine.arguments[2], forceHEVC: Bool(CommandLine.arguments[1]))
