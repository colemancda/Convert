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
    // Wait for keystroke so as to allow attaching external debugger via Xcode
    print("Press any key to continue")
    readLine()
    // Xcode cannot see `ffmpeg` or `trash` for some reason, unless
    // you run it manually and attach Xcode later
    try! installDependencies()
    try Converter.convert(path: CommandLine.arguments[2], forceHEVC: Bool(CommandLine.arguments[1]))
} catch {
    print("\nConversion error: \(error.localizedDescription)\n")
}
