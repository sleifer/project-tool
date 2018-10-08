//
//  BuildCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/29/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class BuildCommand: Command {
    var dir = FileManager.default.currentDirectoryPath
    var configurationFlags: [String] = ["-configuration", "Debug"]
    var destinationFlags: [String] = []
    var cleanDestinationFlags: [String] = []
    var dryrun: Bool = false
    var preClean: Bool = false

    required init() {
    }

    // swiftlint:disable cyclomatic_complexity

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.option("--root") != nil {
            if let path = findGitRoot() {
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
        let projectPath = findXcodeProject(dir)
        if projectPath.count == 0 {
            print("No Xcode project in current directory.")
        } else {
            if projectPath.hasSuffix(".xcodeproj") {
                valid = true
            } else {
                if let scheme = findWorkspaceScheme(projectPath) {
                    valid = true
                    args.append(contentsOf: ["-workspace", projectPath, "-scheme", scheme])
                    cleanArgs.append(contentsOf: ["-workspace", projectPath, "-scheme", scheme])
                }
            }

            args.append(contentsOf: configurationFlags)
            cleanArgs.append(contentsOf: configurationFlags)
            args.append(contentsOf: destinationFlags)
            cleanArgs.append(contentsOf: cleanDestinationFlags)
        }

        if valid == false {
            print("Couldn't generate a valid xcodebuild command.")
            return
        }

        let dstBinaryPath = findDstBinaryPath(args)
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
                ProcessRunner.runCommand(cleanArgs, echo: true)
            }
        }
        // build
        print("--- ---")
        print("\(args.joined(separator: " "))")
        print("--- ---")
        if dryrun == false {
            ProcessRunner.runCommand(args, echo: true)

            // clean up build directory
            let buildDir = projectPath.deletingLastPathComponent.appendingPathComponent("build")
            let dfm = FileManager.default
            if dfm.fileExists(atPath: buildDir) == true {
                do {
                    try dfm.removeItem(atPath: buildDir)
                } catch {
                }
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

    func findGitRoot() -> String? {
        let proc = ProcessRunner.runCommand("git", args: ["rev-parse", "--show-toplevel"])
        if proc.status == 0 {
            return proc.stdOut.trimmed()
        } else {
            print(proc.stdErr)
        }
        return nil
    }

    func findXcodeProject(_ path: String) -> String {
        var projectDir: String = ""

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            for file in contents {
                if projectDir.count == 0 && file.hasSuffix(".xcodeproj") == true {
                    projectDir = path.appendingPathComponent(file)
                }
                if file.hasSuffix(".xcworkspace") == true {
                    projectDir = path.appendingPathComponent(file)
                }
            }
        } catch {
            print(error)
        }

        return projectDir
    }

    fileprivate func findWorkspaceScheme(_ projectPath: String) -> String? {
        let proc = ProcessRunner.runCommand("xcodebuild", args: ["-list", "-workspace", projectPath, "-json"])
        if proc.status == 0 {
            let jsonStr = proc.stdOut.trimmed()
            if let jsonData = jsonStr.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    if let root = json as? [String: Any] {
                        if let workspace = root["workspace"] as? [String: Any] {
                            let name = workspace["name"] as? String
                            let schemes = workspace["schemes"] as? [String]

                            if let name = name, let schemes = schemes {
                                if schemes.contains(name) == false {
                                    return schemes[0]
                                } else {
                                    return name
                                }
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
        return nil
    }

    fileprivate func findDstBinaryPath(_ args: [String]) -> String? {
        var targetBuildDir: String?
        var executableName: String?
        var envargs = args
        envargs.append("-showBuildSettings")
        let runner = ProcessRunner.runCommand(envargs)
        if runner.status == 0 {
            let lines = runner.stdOut.trimmed().lines()
            for line in lines {
                let trimLine = line.trimmed()
                if trimLine.hasPrefix("TARGET_BUILD_DIR") {
                    let parts = trimLine.components(separatedBy: " = ")
                    if parts.count == 2 {
                        targetBuildDir = parts[1].trimmed()
                    }
                } else if trimLine.hasPrefix("FULL_PRODUCT_NAME") {
                    let parts = trimLine.components(separatedBy: " = ")
                    if parts.count == 2 {
                        executableName = parts[1].trimmed()
                    }
                }
            }
        }
        if let theTargetBuildDir = targetBuildDir, let theExecutableName = executableName {
            return theTargetBuildDir.appendingPathComponent(theExecutableName)
        }

        return nil
    }
}
