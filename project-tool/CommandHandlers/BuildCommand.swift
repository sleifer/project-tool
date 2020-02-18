//
//  BuildCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/29/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import CommandLineCore
import Foundation

class BuildCommand: Command {
    var dir = FileManager.default.currentDirectoryPath
    var configurationFlags: [String] = ["-configuration", "Debug"]
    var destinationFlags: [String] = []
    var cleanDestinationFlags: [String] = []
    var dryrun: Bool = false
    var preClean: Bool = false

    required init() {}

    // swiftlint:disable cyclomatic_complexity

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.option("--root") != nil {
            if let path = Helpers.findGitRoot() {
                dir = path
            } else {
                return
            }
        }

        if cmd.option("--clean") != nil {
            preClean = true
        }

        if cmd.option("--dryrun") != nil {
            dryrun = true
            print("Dry Run...")
        }

        if cmd.option("--release") != nil {
            configurationFlags = ["-configuration", "Release"]
        }

        var destinationPath = ""
        var dstCount = 0

        if cmd.option("--applications") != nil {
            destinationPath = "/Applications"
            dstCount += 1
        }
        if cmd.option("--bin") != nil {
            destinationPath = "~/bin".expandingTildeInPath
            dstCount += 1
        }
        if cmd.option("--desktop") != nil {
            destinationPath = "~/Desktop".expandingTildeInPath
            dstCount += 1
        }
        if let outOption = cmd.option("--out") {
            destinationPath = outOption.arguments[0]
            dstCount += 1
        }

        if dstCount > 1 {
            print("Only one build destination can be specified.")
            return
        }

        if destinationPath.count != 0 {
            destinationFlags = ["DEPLOYMENT_LOCATION=YES", "DSTROOT=/", "INSTALL_PATH=\(destinationPath)"]
            cleanDestinationFlags = ["DEPLOYMENT_LOCATION=YES", "INSTALL_PATH=\(destinationPath)", "clean"]
        }

        // build up command args
        var args: [String] = ["xcodebuild"]
        var cleanArgs: [String] = ["xcodebuild"]
        var valid: Bool = false

        guard let projectPath = Helpers.findXcodeProject(dir) else {
            print("No Xcode project in current directory.")
            return
        }

        if projectPath.hasSuffix(".xcodeproj") {
            valid = true
        } else {
            if let scheme = Helpers.findWorkspaceScheme(projectPath) {
                valid = true
                args.append(contentsOf: ["-workspace", projectPath, "-scheme", scheme])
                cleanArgs.append(contentsOf: ["-workspace", projectPath, "-scheme", scheme])
            }
        }

        args.append(contentsOf: configurationFlags)
        cleanArgs.append(contentsOf: configurationFlags)
        args.append(contentsOf: destinationFlags)
        cleanArgs.append(contentsOf: cleanDestinationFlags)

        if valid == false {
            print("Couldn't generate a valid xcodebuild command.")
            return
        }

        let dstBinaryPath = Helpers.findDstBinaryPath(args)
        if cmd.option("--clear") != nil {
            if let path = dstBinaryPath {
                if dryrun == false {
                    if FileManager.default.fileExists(atPath: path) == true {
                        let url = URL(fileURLWithPath: path)
                        do {
                            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                        } catch {
                            print("Failed to move (\(url.path)) to the trash.")
                        }
                    }
                } else {
                    print("Would delete: \(path)")
                }
            } else {
                print("Couldn't determine target binary path to delete.")
                return
            }
        }

        // clean
        if preClean == true {
            print("--- ---")
            print("\(cleanArgs.joined(separator: " "))")
            print("--- ---")
            if dryrun == false {
                ProcessRunner.runCommand(cleanArgs, echoOutput: true)
            }
        }
        // build
        print("--- ---")
        print("\(args.joined(separator: " "))")
        print("--- ---")
        if dryrun == false {
            ProcessRunner.runCommand(args, echoOutput: true)

            // clean up build directory
            let buildDir = projectPath.deletingLastPathComponent.appendingPathComponent("build")
            let dfm = FileManager.default
            if dfm.fileExists(atPath: buildDir) == true {
                do {
                    try dfm.removeItem(atPath: buildDir)
                } catch {}
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "build"
        command.synopsis = "Build project in various ways."

        var clean = CommandOption()
        clean.shortOption = "-c"
        clean.longOption = "--clean"
        clean.help = "Do a clean before building."
        command.options.append(clean)

        var clear = CommandOption()
        clear.shortOption = "-t"
        clear.longOption = "--clear"
        clear.help = "Delete any existing target binary before building."
        command.options.append(clear)

        var dryrun = CommandOption()
        dryrun.shortOption = "-n"
        dryrun.longOption = "--dryrun"
        dryrun.help = "Output build command but do not build anything."
        command.options.append(dryrun)

        var release = CommandOption()
        release.shortOption = "-r"
        release.longOption = "--release"
        release.help = "Build Release instead of Debug."
        command.options.append(release)

        var inApp = CommandOption()
        inApp.shortOption = "-a"
        inApp.longOption = "--applications"
        inApp.help = "Build into /Applications."
        command.options.append(inApp)

        var inBin = CommandOption()
        inBin.shortOption = "-b"
        inBin.longOption = "--bin"
        inBin.help = "Build into ~/bin."
        command.options.append(inBin)

        var inDesk = CommandOption()
        inDesk.shortOption = "-d"
        inDesk.longOption = "--desktop"
        inDesk.help = "Build into ~/Desktop."
        command.options.append(inDesk)

        var inPassed = CommandOption()
        inPassed.shortOption = "-o"
        inPassed.longOption = "--out"
        inPassed.argumentCount = 1
        inPassed.hasFileArguments = true
        inPassed.help = "Build into <param>."
        command.options.append(inPassed)

        return command
    }
}
