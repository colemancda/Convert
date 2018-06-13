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
    
    func encapsulated() -> String {
        return "\"\(self)\""
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
        try Command.run(.trash, arguments: self.path.encapsulated())
    }
    
    private enum MediaType {
        case video
        case audio
    }
    
    private func ffprobe(type: MediaType) throws -> String {
        let stream: String
        
        switch type {
        case .video:
            stream = "v:0"
        case .audio:
            stream = "a:0"
        }
        
        return try Command.run(.ffprobe, arguments: [
            "-v",
            "error",
            "-select_streams",
            stream,
            "-show_entries",
            "stream=codec_name",
            "-of",
            "default=nokey=1:noprint_wrappers=1",
            self.path.encapsulated()
        ])
    }
    
    func videoCodec() throws -> Converter.VideoCodec? {
        var codec = try self.ffprobe(type: .video)
        codec = codec.chomp()
        
        if let vcodec = Converter.VideoCodec(rawValue: codec) {
            return vcodec
        }
        
        return nil
    }
    
    func audioCodec() throws -> Converter.AudioCodec? {
        var codec = try self.ffprobe(type: .audio)
        codec = codec.chomp()
        
        if let acodec = Converter.AudioCodec(rawValue: codec) {
            return acodec
        }
        
        return nil
    }
}
