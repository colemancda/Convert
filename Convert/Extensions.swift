//
//  Extensions.swift
//  Convert
//
//  Created by Mark Lowell on 6/6/18.
//  Copyright © 2018 Mark Malstrom. All rights reserved.
//

import Foundation

extension String {
    func chomp() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory:&isDir) {
            return isDir.boolValue
        } else {
            return false
        }
    }
    
    var isFile: Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory:&isDir) {
            return !isDir.boolValue
        } else {
            return false
        }
    }
}

extension Bool {
    init(_ string: String) {
        self = (string.lowercased() == "y") || (string.lowercased() == "yes")
    }
}

extension File {
    func trash() throws {
        try shellOut(to: "trash", arguments: ["\(self.path)"])
    }
    
    func videoCodec() throws -> VideoCodec? {
        var codec = try shellOut(to: "ffprobe", arguments: [
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=codec_name",
            "-of",
            "default=nokey=1:noprint_wrappers=1",
            "\(self.path)"
            ])
        codec = codec.chomp()
        
        if let vcodec = VideoCodec(rawValue: codec) {
            return vcodec
        }
        
        return nil
    }
    
    func audioCodec() throws -> AudioCodec? {
        var codec = try shellOut(to: "ffprobe", arguments: [
            "-v",
            "error",
            "-select_streams",
            "a:0",
            "-show_entries",
            "stream=codec_name",
            "-of",
            "default=nokey=1:noprint_wrappers=1",
            "\(self.path)"
            ])
        codec = codec.chomp()
        
        if let acodec = AudioCodec(rawValue: codec) {
            return acodec
        }
        
        return nil
    }
}
