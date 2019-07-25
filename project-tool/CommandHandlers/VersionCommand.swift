//
//  VersionCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 1/14/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore

class VersionCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var result: ProcessRunner?
        if cmd.option("--bump") != nil {
            result = ProcessRunner.runCommand(["agvtool", "bump", "-all"], echoOutput: true)
        } else if let cmd = cmd.option("--bundle") {
            result = ProcessRunner.runCommand(["agvtool", "new-version", "-all", cmd.arguments[0]], echoOutput: true)
        }

        if let cmd = cmd.option("--marketing") {
            result = ProcessRunner.runCommand(["agvtool", "new-marketing-version", cmd.arguments[0]], echoOutput: true)
        }

        if cmd.option("--bump") == nil && cmd.option("--bundle") == nil && cmd.option("--marketing") == nil {
            print("Marketing Version:")
            ProcessRunner.runCommand(["agvtool", "mvers", "-terse1"], echoOutput: true)
            print("Build Number:")
            ProcessRunner.runCommand(["agvtool", "vers", "-terse"], echoOutput: true)
        }

        if let result = result, result.status == 0 {
            let updates = result.stdOut.regex("Updated CFBundle.*/(.*-stamped\\.plist)\"")
            for update in updates {
                backCopyVersions(from: update[1])
            }
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "version"
        command.synopsis = "AGV helpers."

        var bumpCmd = CommandOption()
        bumpCmd.shortOption = "-b"
        bumpCmd.longOption = "--bump"
        bumpCmd.help = "Bump version."
        command.options.append(bumpCmd)

        var versionCmd = CommandOption()
        versionCmd.shortOption = "-v"
        versionCmd.longOption = "--bundle"
        versionCmd.argumentCount = 1
        versionCmd.help = "Set bundle version."
        command.options.append(versionCmd)

        var marketingCmd = CommandOption()
        marketingCmd.shortOption = "-m"
        marketingCmd.longOption = "--marketing"
        marketingCmd.argumentCount = 1
        marketingCmd.help = "Set marketing version"
        command.options.append(marketingCmd)

        return command
    }

    func backCopyVersions(from stampedFile: String) {
        let dir = FileManager.default.currentDirectoryPath

        if let enumerator = FileManager.default.enumerator(atPath: dir) {
            for item in enumerator {
                if let filePath = item as? String {
                    if filePath.contains(stampedFile) {
                        let srcPath = dir.appendingPathComponent(filePath)
                        let dstPath = srcPath.replacingOccurrences(of: "-stamped", with: "")

                        var bundleVersion: String?
                        var bundleShortVersion: String?
                        do {
                            let inUrl = URL(fileURLWithPath: srcPath)
                            let inData = try Data(contentsOf: inUrl)
                            var plist = try PropertyListSerialization.propertyList(from: inData, options: [.mutableContainersAndLeaves], format: nil) as? [String: AnyObject]
                            bundleVersion = plist?["CFBundleVersion"] as? String
                            bundleShortVersion = plist?["CFBundleShortVersionString"] as? String
                        } catch {
                            print(error)
                        }

                        do {
                            let inUrl = URL(fileURLWithPath: dstPath)
                            let inData = try Data(contentsOf: inUrl)
                            var plist = try PropertyListSerialization.propertyList(from: inData, options: [.mutableContainersAndLeaves], format: nil) as? [String: AnyObject]
                            if let bundleVersion = bundleVersion {
                                plist?["CFBundleVersion"] = bundleVersion as AnyObject
                            }
                            if let bundleShortVersion = bundleShortVersion {
                                plist?["CFBundleShortVersionString"] = bundleShortVersion as AnyObject
                            }
                            let outData = try PropertyListSerialization.data(fromPropertyList: plist as Any, format: .xml, options: 0)
                            let outUrl = URL(fileURLWithPath: dstPath)
                            try outData.write(toFileURL: outUrl)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }

    }
}
