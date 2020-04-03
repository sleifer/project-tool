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
        if cmd.boolOption("--root") {
            if let path = Helpers.findGitRoot() {
                dir = path
            } else {
                return
            }
        }

        if cmd.boolOption("--clean") {
            preClean = true
        }

        if cmd.boolOption("--dryrun") {
            dryrun = true
            print("Dry Run...")
        }

        if cmd.boolOption("--release") {
            configurationFlags = ["-configuration", "Release"]
        }

        var destinationPath = ""
        var dstCount = 0

        if cmd.boolOption("--applications") {
            destinationPath = "/Applications"
            dstCount += 1
        }
        if cmd.boolOption("--bin") {
            destinationPath = "~/bin".expandingTildeInPath
            dstCount += 1
        }
        if cmd.boolOption("--desktop") {
            destinationPath = "~/Desktop".expandingTildeInPath
            dstCount += 1
        }
        if cmd.boolOption("--install") {
            if let installPath = try? String(contentsOf: URL(fileURLWithPath: dir).appendingPathComponent(".INSTALL_PATH")) {
                let fullInstallPath = installPath.expandingTildeInPath
                if FileManager.default.fileExists(atPath: fullInstallPath) == true {
                    destinationPath = fullInstallPath
                    dstCount += 1
                } else {
                    print("\(fullInstallPath) from .INSTALL_PATH is missing")
                    return
                }
            } else {
                print(".INSTALL_PATH file missing")
                return
            }
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
            if let targetOption = cmd.option("--target") {
                let target = targetOption.arguments[0]
                args.append(contentsOf: ["-target", target])
                cleanArgs.append(contentsOf: ["-target", target])
                valid = true
            } else if let schemeOption = cmd.option("--scheme") {
                let scheme = schemeOption.arguments[0]
                args.append(contentsOf: ["-scheme", scheme])
                cleanArgs.append(contentsOf: ["-scheme", scheme])
                valid = true
            }
        } else {
            if let schemeOption = cmd.option("--scheme") {
                let scheme = schemeOption.arguments[0]
                args.append(contentsOf: ["-scheme", scheme])
                cleanArgs.append(contentsOf: ["-scheme", scheme])
                valid = true
            }
            args.append(contentsOf: ["-workspace", projectPath])
            cleanArgs.append(contentsOf: ["-workspace", projectPath])
        }

        args.append(contentsOf: configurationFlags)
        cleanArgs.append(contentsOf: configurationFlags)
        args.append(contentsOf: destinationFlags)
        cleanArgs.append(contentsOf: cleanDestinationFlags)

        if valid == false {
            print("Couldn't generate a valid xcodebuild command, make sure a target or scheme is specified.")
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

        do {
            let temporaryDirectoryURL = URL(fileURLWithPath: "/tmp")
            let temporaryFilename = "build-\(UUID().uuidString).log"
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
            let path = temporaryFileURL.path
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            let logFile = try FileHandle(forWritingTo: temporaryFileURL)
            defer {
                logFile.closeFile()
            }

            print("---")
            print("Writing build output to: \(path)")
            print("--- Helpers")
            print("\(path)")
            print("open \(path)")
            print("rm \(path)")
            print("---")

            // clean
            if preClean == true {
                if let outData = "--- ---\n".data(using: .utf8) {
                    logFile.write(outData)
                }
                if let outData = "\(cleanArgs.joined(separator: " "))\n".data(using: .utf8) {
                    logFile.write(outData)
                }
                if let outData = "--- ---\n".data(using: .utf8) {
                    logFile.write(outData)
                }
                if dryrun == false {
                    ProcessRunner.runCommand(cleanArgs, outputHandler: { _, outStr, errStr in
                        if let outStr = outStr {
                            if outStr.hasPrefix("** ") {
                                print(outStr.trimmed())
                            }
                            if let outData = outStr.data(using: .utf8) {
                                logFile.write(outData)
                            }
                        }
                        if let errStr = errStr {
                            if errStr.hasPrefix("** ") {
                                print(errStr.trimmed())
                            }
                            if let errData = errStr.data(using: .utf8) {
                                logFile.write(errData)
                            }
                        }
                    })
                }
            }
            // build
            if let outData = "--- ---\n".data(using: .utf8) {
                logFile.write(outData)
            }
            if let outData = "\(args.joined(separator: " "))\n".data(using: .utf8) {
                logFile.write(outData)
            }
            if let outData = "--- ---\n".data(using: .utf8) {
                logFile.write(outData)
            }
            if dryrun == false {
                ProcessRunner.runCommand(args, outputHandler: { _, outStr, errStr in
                    if let outStr = outStr {
                        if outStr.hasPrefix("** ") {
                            print(outStr.trimmed())
                        }
                        if let outData = outStr.data(using: .utf8) {
                            logFile.write(outData)
                        }
                    }
                    if let errStr = errStr {
                        if errStr.hasPrefix("** ") {
                            print(errStr.trimmed())
                        }
                        if let errData = errStr.data(using: .utf8) {
                            logFile.write(errData)
                        }
                    }
                })

                // clean up build directory
                var buildFolders: [String] = []
                gatherBuildFolders(in: projectPath.deletingLastPathComponent, paths: &buildFolders, core: core)
                let dfm = FileManager.default
                for folder in buildFolders {
                    if dfm.fileExists(atPath: folder) == true {
                        do {
                            try dfm.removeItem(atPath: folder)
                        } catch {}
                    }
                }
            }
        } catch {
            print(error)
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

        var target = CommandOption()
        target.shortOption = "-t"
        target.longOption = "--target"
        target.argumentCount = 1
        target.help = "Specify target to build."
        target.completionCallback = { () -> [String] in
            if let path = Helpers.findXcodeProject(FileManager.default.currentDirectoryPath) {
                if path.hasSuffix(".xcodeproj") {
                    let targets = Helpers.findProjectTargets(path)
                    return targets
                }
            }
            return []
        }
        command.options.append(target)

        var scheme = CommandOption()
        scheme.shortOption = "-s"
        scheme.longOption = "--scheme"
        scheme.argumentCount = 1
        scheme.help = "Specify scheme to build."
        scheme.completionCallback = { () -> [String] in
            if let path = Helpers.findXcodeProject(FileManager.default.currentDirectoryPath) {
                if path.hasSuffix(".xcodeproj") {
                    let schemes = Helpers.findProjectSchemes(path)
                    return schemes
                } else {
                    let schemes = Helpers.findWorkspaceSchemes(path)
                    return schemes
                }
            }
            return []
        }
        command.options.append(scheme)

        var clear = CommandOption()
        clear.shortOption = "-l"
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

        var installPathDesk = CommandOption()
        installPathDesk.shortOption = "-i"
        installPathDesk.longOption = "--install"
        installPathDesk.help = "Build into path from .INSTALL_PATH file."
        command.options.append(installPathDesk)

        var inPassed = CommandOption()
        inPassed.shortOption = "-o"
        inPassed.longOption = "--out"
        inPassed.argumentCount = 1
        inPassed.hasFileArguments = true
        inPassed.help = "Build into <param>."
        command.options.append(inPassed)

        return command
    }

    func gatherBuildFolders(in dir: String, paths: inout [String], core: CommandCore) {
        core.setCurrentDir(core.baseSubPath(dir))

        if FileManager.default.fileExists(atPath: dir.appendingPathComponent("build")) == true {
            paths.append(dir.appendingPathComponent("build"))
        }

        // get submodules
        let runner2 = ProcessRunner.runCommand("git", args: ["submodule"])
        let text = runner2.stdOut
        var modules: [String] = []
        let matches = text.regex(SubmoduleParseRegex.pattern())
        for match in matches {
            if match.count == SubmoduleParseRegex.count.rawValue {
                let path = match[SubmoduleParseRegex.pathRoot.rawValue] + match[SubmoduleParseRegex.name.rawValue]
                modules.append(path)
            }
        }
        modules = modules.map { (text) -> String in
            dir.appendingPathComponent(text)
        }

        core.resetCurrentDir()

        for aModule in modules {
            gatherBuildFolders(in: aModule, paths: &paths, core: core)
        }
    }
}
