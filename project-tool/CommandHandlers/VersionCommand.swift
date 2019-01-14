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
        if cmd.option("--bump") != nil {
            ProcessRunner.runCommand(["agvtool", "bump", "-all"], echoOutput: true)
        } else if let cmd = cmd.option("--bundle") {
            ProcessRunner.runCommand(["agvtool", "new-version", "-all", cmd.arguments[0]], echoOutput: true)
        } else if let cmd = cmd.option("--marketing") {
            ProcessRunner.runCommand(["agvtool", "new-marketing-version", cmd.arguments[0]], echoOutput: true)
        } else {
            ProcessRunner.runCommand(["agvtool", "mvers"], echoOutput: true)
            ProcessRunner.runCommand(["agvtool", "vers"], echoOutput: true)
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
}
