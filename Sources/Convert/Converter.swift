//
//  Converter.swift
//  Convert
//
//  Created by Mark Lowell on 6/6/18.
//  Copyright © 2018 Mark Malstrom. All rights reserved.
//

import Foundation
import Files

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
    
    enum Error: Swift.Error, LocalizedError {
        case unknownError(stderr: String, statusCode: Int)
        case unknownFileType
        case noSuchFileOrDirectory
        
        var errorDescription: String? {
            switch self {
            case let .unknownError(err, code):
                return NSLocalizedString("An unknown error with status \(code) occured: \(err)")
            case .unknownFileType:
                return NSLocalizedString("The file you are trying to convert is invalid or may not exist.")
            case .noSuchFileOrDirectory:
                return NSLocalizedString("The file you are trying to convert does not exist.")
            }
        }
    }
    
    private let videoFile: File
    private let outputPath: String
    private var ffmpegArgs: [String]
    
    init(_ videoPath: String, forceHEVC: Bool) throws {
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
    
    init(_ videoFile: File, forceHEVC: Bool) throws {
        try self.init(videoFile.path, forceHEVC: forceHEVC)
    }
    
    private static func buildArgs(path: String, output: String, _ forceHEVC: Bool, _ vcodec: VideoCodec?, _ acodec: AudioCodec?, _ size: Int) throws -> [String] {
        let convertVideo = (vcodec == nil) || forceHEVC
        let convertAudio = (acodec == nil) || forceHEVC
        let addCompression = size > 3_000_000_000

        // Silent commands seemed not to help
        let silentCommands: [String] = ["-loglevel", "panic"]
        let videoCommands: [String] = convertVideo ? ["-c:v", "libx265"] : ["-vcodec", "copy"]
        let videoTag: [String] = (convertVideo || vcodec == .hevc) ? ["-tag:v", "hvc1"] : []
        let videoQuality: [String] = (convertVideo && addCompression) ? ["-preset", "veryfast", "-crf", "25"] : []
        let audioCommands: [String] = convertAudio ? ["-c:a", "libfdk_aac", "-b:a", "320k"] : ["-acodec", "copy"]

        // Takes an array of arrays from above and flattens them into one array
        // Compiler could not type check the complete expression in reasonable time otherwise
        let joined: [String] = [silentCommands, videoCommands, videoTag, videoQuality, audioCommands].joined().map { $0 }
        return ["-i", path.encapsulated(), "-map_metadata", "-1"] + joined + [output.encapsulated()]
    }
    
    private func convert() throws {
        print("\nConverting...")
        try! Command.run(.ffmpeg, arguments: self.ffmpegArgs)
        guard FileManager.default.fileExists(atPath: self.outputPath) else { fatalError("ffmpeg did not work") }
        print("Finished running ffmpeg.")
        let destinationFolder = self.videoFile.parent!
        try! self.videoFile.trash()
        guard !FileManager.default.fileExists(atPath: self.videoFile.path) else { fatalError("trash did not work") }
        print("Trashed.")
        try! File(path: self.outputPath).move(to: destinationFolder)
        // TODO `guard` whether file was actually moved
        print("Moved.")
        print("Done!")
    }
    
    static func convert(path: String, forceHEVC: Bool) throws {
        let expandedPath = path.expandingTildeInPath()
        
        if expandedPath.isDirectory {
            for (_, file) in try Folder(path: path).files.enumerated() {
                // Only convert video files
                if let ext = file.extension, !ext.isEqual(to: ["mp4", "mkv", "avi", "webm"]) {
                    continue
                }
                
                // If compressing, ignore mp4 HEVC files, already compressed
                if try forceHEVC && (file.extension == "mp4") && (file.videoCodec() == .hevc) {
                    continue
                }
                
                // If not compressing (i.e. converting), ignore mp4 files -- they're already converted
                if !forceHEVC && (file.extension == "mp4") {
                    continue
                }
                
                try Converter(file, forceHEVC: forceHEVC).convert()
            }
        } else if expandedPath.isFile {
            try Converter(expandedPath, forceHEVC: forceHEVC).convert()
        } else {
            throw Error.unknownFileType
        }
    }
}
