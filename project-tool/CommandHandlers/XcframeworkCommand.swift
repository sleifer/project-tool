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

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.option("--root") != nil {
            if let path = Helpers.findGitRoot() {
                dir = path
            } else {
                return
            }
        }

        let projectPath = Helpers.findXcodeProject(dir)
        if projectPath.count == 0 {
            print("No Xcode project in current directory.")
            return
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "xcframework"
        command.synopsis = "Build an xcframework from current project."

        return command
    }
}
