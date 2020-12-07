//
//  StampCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 1/15/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore

class StampCommand: Command {
    required init() {}

    // swiftlint:disable cyclomatic_complexity

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.parameters.count < 2 {
            print("Missing required parameters.")
            return
        }

        let targetFilter = cmd.parameters[0]
        let dstPath = cmd.parameters[1].fullPath

        var dir = FileManager.default.currentDirectoryPath
        if cmd.boolOption("--root") == true {
            if let path = Helpers.findGitRoot() {
                dir = path
            } else {
                print("Could not find git root")
                return
            }
        }
        let baseDirUrl = URL(fileURLWithPath: dir)

        let subCommand = VersionCommand()
        subCommand.baseDirUrl = baseDirUrl

        var marketingVersion: String = ""
        var projectVersion: String = ""

        do {
            try subCommand.locateFiles()

            let matchedTarget = subCommand.targets.filter { (target) -> Bool in
                if target.target.openStepComment == targetFilter {
                    return true
                }
                return false
            }

            if let target = matchedTarget.first {
                try subCommand.determineVersionState(target: target)

                switch target.versionSystemState {
                case .unknown:
                    print("Version unknown")
                    return
                case .genericPresent:
                    print("Generic Versioning")
                    marketingVersion = target.marketingVersion
                    projectVersion = target.projectVersion
                case .appleGenericPresent:
                    print("Apple Generic Versioning")
                    marketingVersion = target.marketingVersion
                    projectVersion = target.projectVersion
                case .genericReady:
                    print("Generic Versioning not set up")
                    return
                case .appleGenericReady:
                    print("Apple Generic Versioning not set up")
                    return
                }
            } else {
                print("Could not locate any targets")
                return
            }
        } catch {
            print("Exception: \(error)")
            return
        }

        var sha = currentGitHash()
        if isRepositoryDirty() == true {
            sha += "+"
        }

        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy H:mm:ss.SSS"
        let buildDate = formatter.string(from: date)

        let fileText = """
        struct VersionStrings {
            static let marketingVersion: String = "\(marketingVersion)"
            static let projectVersion: String = "\(projectVersion)"
            static let gitHash: String = "\(sha)"
            static let fullVersion: String = "\(marketingVersion) (\(projectVersion)) <\(sha)>"
            static let buildDate: String = "\(buildDate)>"
        }
        """

        do {
            print("Written to: \(dstPath)")
            try fileText.write(to: URL(fileURLWithPath: dstPath), atomically: true, encoding: .utf8)
        } catch {
            print("Exception: \(error)")
        }
    }

    // swiftlint:enable cyclomatic_complexity

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "stamp"
        command.synopsis = "Embed git SHA in build."
        command.hasFileParameters = true

        var src = ParameterInfo()
        src.hint = "target"
        src.help = "Target to pull version from"
        command.requiredParameters.append(src)

        var dst = ParameterInfo()
        dst.hint = "dst"
        dst.help = "Destination Info.plist"
        command.requiredParameters.append(dst)

        return command
    }

    func currentGitHash() -> String {
        let result = ProcessRunner.runCommand(["git", "rev-parse", "--verify", "HEAD"])
        if result.status == 0 {
            return result.stdOut.trimmed()[0..<8]
        }
        return ""
    }

    func isRepositoryDirty() -> Bool {
        let result = ProcessRunner.runCommand(["git", "status"])
        if result.status == 0 {
            if result.stdOut.trimmed().contains("working tree clean") == false {
                return true
            }
        }
        return false
    }
}
