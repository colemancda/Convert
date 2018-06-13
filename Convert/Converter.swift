//
//  Converter.swift
//  Convert
//
//  Created by Mark Lowell on 6/6/18.
//  Copyright © 2018 Mark Malstrom. All rights reserved.
//

import Foundation

struct Converter {
    enum VideoCodec: String {
        case h264
        case hevc
    }
    
    enum AudioCodec: String {
        case ac3
        case eac3
        case aac
    }
    
    enum Error: Swift.Error {
        case unknownFileType
        var localizedDescription: String {
            return "The file type you have entered is unknown."
        }
    }
    
    private let videoFile: File
    private let outputPath: String
    private var ffmpegArgs: [String]
    
    init(videoPath: String, forceHEVC: Bool) throws {
        self.videoFile = try File(path: videoPath)
        self.outputPath = "\(FileSystem().temporaryFolder.path)\(self.videoFile.nameExcludingExtension).mp4"
        let vcodec = try self.videoFile.videoCodec()
        let acodec = try self.videoFile.audioCodec()
        let size = try self.videoFile.size()
        self.ffmpegArgs = try Converter.buildArgs(
            path: self.videoFile.path,
            output: self.outputPath,
            forceHEVC, vcodec, acodec, size
        )
    }
    
    init(videoFile: File, forceHEVC: Bool) throws {
        self.videoFile = videoFile
        self.outputPath = "\(FileSystem().temporaryFolder.path)\(self.videoFile.nameExcludingExtension).mp4"
        let vcodec = try self.videoFile.videoCodec()
        let acodec = try self.videoFile.audioCodec()
        let size = try self.videoFile.size()
        self.ffmpegArgs = try Converter.buildArgs(
            path: self.videoFile.path,
            output: self.outputPath,
            forceHEVC, vcodec, acodec, size
        )
    }
    
    private static func buildArgs(path: String, output: String, _ forceHEVC: Bool, _ vcodec: VideoCodec?, _ acodec: AudioCodec?, _ size: Int) throws -> [String] {
        let convertVideo = (vcodec == nil) || forceHEVC
        let convertAudio = (acodec == nil) || forceHEVC
        let addCompression = size > 3_000_000_000
        
        let videoCommands = convertVideo ? ["-c:v", "libx265"] : ["-vcodec", "copy"]
        let videoTag = (convertVideo || vcodec == .hevc) ? ["-tag:v", "hvc1"] : []
        let videoQuality = (convertVideo && addCompression) ? ["-preset", "veryfast", "-crf", "25"] : []
        let audioCommands = convertAudio ? ["-c:a", "libfdk_aac", "-b:a", "320k"] : ["-acodec", "copy"]
        
        return ["-i", path.encapsulated(), "-map_metadata", "-1"] + videoCommands + videoTag + videoQuality + audioCommands + [output.encapsulated()]
    }
    
    private func convert() throws {
        print("\nConverting...")
        try Command.run(.ffmpeg, arguments: self.ffmpegArgs)
        print("Finished running ffmpeg.")
        let destinationFolder = self.videoFile.parent!
        try self.videoFile.trash()
        print("Trashed.")
        try File(path: self.outputPath).move(to: destinationFolder)
        print("Moved.")
        print("Done!")
    }
    
    static func convert(path: String, forceHEVC: Bool) throws {
        if path.isDirectory {
            for (_, file) in try Folder(path: path).files.enumerated() {
                // Only convert video files
                if file.extension != "mp4" &&
                    file.extension != "mkv" &&
                    file.extension != "avi" &&
                    file.extension != "webm" {
                    continue
                }
                
                let vcodec = try file.videoCodec()
                
                // If compressing, ignore mp4 HEVC files, already compressed
                if forceHEVC && (file.extension == "mp4") && (vcodec == .hevc) {
                    continue
                }
                
                // If converting, ignore mp4 files -- they're already converted
                if !forceHEVC && (file.extension == "mp4") {
                    continue
                }
                
                try Converter(videoFile: file, forceHEVC: forceHEVC).convert()
            }
        } else if path.isFile {
            try Converter(videoPath: path, forceHEVC: forceHEVC).convert()
        } else {
            throw Error.unknownFileType
        }
    }
}
