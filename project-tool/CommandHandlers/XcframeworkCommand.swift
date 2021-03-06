//
//  XcframeworkCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 1/25/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore

class XcframeworkCommand: Command {
    var dir = FileManager.default.currentDirectoryPath

    required init() {
    }

    // swiftlint:disable cyclomatic_complexity

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.option("--root") != nil {
            if let path = Helpers.findGitRoot() {
                dir = path
            } else {
                return
            }
        }

        var dryrun: Bool = false
        if cmd.option("--dryrun") != nil {
            dryrun = true
            print("Dry Run...")
        }

        var name: String?

        if let nameOption = cmd.option("--name") {
            name = nameOption.arguments[0]
        }

        guard let projectPath = Helpers.findXcodeProject(dir) else {
            print("No Xcode project in current directory.")
            return
        }

        if let info = Helpers.getProjectInfo(projectPath) {
            let schemes = info.schemes
            if schemes.count == 0 {
                print("No schemes found.")
                return
            }

            if name == nil {
                name = info.name
            }
            if let name = name, name.count > 0 {
                var iOSScheme: String?
                var macOSScheme: String?
                var tvOSScheme: String?
                var watchOSScheme: String?

                let wordBreaks = CharacterSet(charactersIn: " .-_")

                for scheme in schemes {
                    let words = scheme.components(separatedBy: wordBreaks)

                    if words.contains("iOS") == true {
                        iOSScheme = scheme
                    } else if words.contains("macOS") == true {
                        macOSScheme = scheme
                    } else if words.contains("tvOS") == true {
                        tvOSScheme = scheme
                    } else if words.contains("watchOS") == true {
                        watchOSScheme = scheme
                    }
                }

                if let scheme = cmd.option("--ios") {
                    iOSScheme = scheme.arguments[0]
                }
                if let scheme = cmd.option("--macos") {
                    macOSScheme = scheme.arguments[0]
                }
                if let scheme = cmd.option("--tvos") {
                    tvOSScheme = scheme.arguments[0]
                }
                if let scheme = cmd.option("--watchos") {
                    watchOSScheme = scheme.arguments[0]
                }

                if iOSScheme == nil && macOSScheme == nil && tvOSScheme == nil && watchOSScheme == nil {
                    print("Could not auto-detect any (i/mac/tv/watch)OS schemes.")
                    return
                }

                print("xcframework name: '\(name)'")
                if let schemeName = iOSScheme {
                    print("Scheme '\(schemeName)' -> iOS (device and simulator)")
                }
                if let schemeName = macOSScheme {
                    print("Scheme '\(schemeName)' -> macOS (device)")
                }
                if let schemeName = tvOSScheme {
                    print("Scheme '\(schemeName)' -> tvOS (device and simulator)")
                }
                if let schemeName = watchOSScheme {
                    print("Scheme '\(schemeName)' -> watchOS (device and simulator)")
                }
                print("- - - - - - - - - -")

                let workDir = "~/Desktop/\(name)-working".expandingTildeInPath

                var createCommand = "xcodebuild -create-xcframework"

                ProcessRunner.runCommand("mkdir \(workDir)", echoCommand: true, echoOutput: true, dryrun: dryrun)

                if let scheme = iOSScheme {
                    ProcessRunner.runCommand("xcodebuild archive -project \(projectPath.lastPathComponent) -scheme \"\(scheme)\" -destination \"generic/platform=iOS\" -archivePath \"\(workDir)/archive/iOS\" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES", echoCommand: true, echoOutput: true, dryrun: dryrun)

                    createCommand.append(" -framework \"\(workDir)/archive/iOS.xcarchive/Products/Library/Frameworks/\(name).framework\"")

                    ProcessRunner.runCommand("xcodebuild archive -project \(projectPath.lastPathComponent) -scheme \"\(scheme)\" -destination \"generic/platform=iOS Simulator\" -archivePath \"\(workDir)/archive/iOS-Simulator\" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES", echoCommand: true, echoOutput: true, dryrun: dryrun)

                    createCommand.append(" -framework \"\(workDir)/archive/iOS-Simulator.xcarchive/Products/Library/Frameworks/\(name).framework\"")
                }

                if let scheme = macOSScheme {
                    ProcessRunner.runCommand("xcodebuild archive -project \(projectPath.lastPathComponent) -scheme \"\(scheme)\" -destination \"generic/platform=macOS\" -archivePath \"\(workDir)/archive/macOS\" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES", echoCommand: true, echoOutput: true, dryrun: dryrun)

                    createCommand.append(" -framework \"\(workDir)/archive/macOS.xcarchive/Products/Library/Frameworks/\(name).framework\"")
                }

                if let scheme = tvOSScheme {
                    ProcessRunner.runCommand("xcodebuild archive -project \(projectPath.lastPathComponent) -scheme \"\(scheme)\" -destination \"generic/platform=tvOS\" -archivePath \"\(workDir)/archive/tvOS\" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES", echoCommand: true, echoOutput: true, dryrun: dryrun)

                    createCommand.append(" -framework \"\(workDir)/archive/tvOS.xcarchive/Products/Library/Frameworks/\(name).framework\"")

                    ProcessRunner.runCommand("xcodebuild archive -project \(projectPath.lastPathComponent) -scheme \"\(scheme)\" -destination \"generic/platform=tvOS Simulator\" -archivePath \"\(workDir)/archive/tvOS-Simulator\" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES", echoCommand: true, echoOutput: true, dryrun: dryrun)

                    createCommand.append(" -framework \"\(workDir)/archive/tvOS-Simulator.xcarchive/Products/Library/Frameworks/\(name).framework\"")
                }

                if let scheme = watchOSScheme {
                    ProcessRunner.runCommand("xcodebuild archive -project \(projectPath.lastPathComponent) -scheme \"\(scheme)\" -destination \"generic/platform=watchOS\" -archivePath \"\(workDir)/archive/watchOS\" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES", echoCommand: true, echoOutput: true, dryrun: dryrun)

                    createCommand.append(" -framework \"\(workDir)/archive/watchOS.xcarchive/Products/Library/Frameworks/\(name).framework\"")

                    ProcessRunner.runCommand("xcodebuild archive -project \(projectPath.lastPathComponent) -scheme \"\(scheme)\" -destination \"generic/platform=watchOS Simulator\" -archivePath \"\(workDir)/archive/watchOS-Simulator\" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES", echoCommand: true, echoOutput: true, dryrun: dryrun)

                    createCommand.append(" -framework \"\(workDir)/archive/watchOS-Simulator.xcarchive/Products/Library/Frameworks/\(name).framework\"")
                }

                createCommand.append(" -output \"\(workDir)/\(name).xcframework\"")
                ProcessRunner.runCommand(createCommand, echoCommand: true, echoOutput: true, dryrun: dryrun)
            }
        } else {
            print("No name provided for xcframework.")
            return
        }
    }

    // swiftlint:enable cyclomatic_complexity

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "xcframework"
        command.synopsis = "Build an xcframework from current project."

        var dryrun = CommandOption()
        dryrun.shortOption = "-d"
        dryrun.longOption = "--dryrun"
        dryrun.help = "Output commands but do not build anything."
        command.options.append(dryrun)

        var iOSScheme = CommandOption()
        iOSScheme.shortOption = "-i"
        iOSScheme.longOption = "--ios"
        iOSScheme.argumentCount = 1
        iOSScheme.help = "Scheme for building for iOS."
        iOSScheme.completionCallback = { () -> [String] in
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
        command.options.append(iOSScheme)

        var macOSScheme = CommandOption()
        macOSScheme.shortOption = "-m"
        macOSScheme.longOption = "--macos"
        macOSScheme.argumentCount = 1
        macOSScheme.help = "Scheme for building for macOS."
        macOSScheme.completionCallback = { () -> [String] in
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
        command.options.append(macOSScheme)

        var tvOSScheme = CommandOption()
        tvOSScheme.shortOption = "-t"
        tvOSScheme.longOption = "--tvos"
        tvOSScheme.argumentCount = 1
        tvOSScheme.help = "Scheme for building for tvOS."
        tvOSScheme.completionCallback = { () -> [String] in
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
        command.options.append(tvOSScheme)

        var watchOSScheme = CommandOption()
        watchOSScheme.shortOption = "-w"
        watchOSScheme.longOption = "--watchos"
        watchOSScheme.argumentCount = 1
        watchOSScheme.help = "Scheme for building for watchOS."
        watchOSScheme.completionCallback = { () -> [String] in
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
        command.options.append(watchOSScheme)

        var name = CommandOption()
        name.shortOption = "-n"
        name.longOption = "--name"
        name.argumentCount = 1
        name.hasFileArguments = true
        name.help = "Name for xcframework."
        command.options.append(name)

        return command
    }
}
