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
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "xcframework"
        command.synopsis = "Build an xcframework from current project."

        return command
    }
}
