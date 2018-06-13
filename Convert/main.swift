//
//  main.swift
//  Convert
//
//  Created by Mark Lowell on 6/6/18.
//  Copyright © 2018 Mark Malstrom. All rights reserved.
//

import Foundation

func installDependencies() throws {
    // FFmpeg
    if try !Command.which("ffmpeg") {
        try Command.brewInstall("ffmpeg", options: ["--with-x265", "--with-fdk-aac", "--HEAD"])
    }
    
    // Trash
    if try !Command.which("trash") {
        try Command.brewInstall("trash")
    }    
}

do {
    // try installDependencies()
    try Converter.convert(path: CommandLine.arguments[2], forceHEVC: Bool(CommandLine.arguments[1]))
} catch {
    print("Conversion error: \(error.localizedDescription)")
}
