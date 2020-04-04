//
//  SchemesCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 4/4/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore

class SchemesCommand: Command {
    required init() {}

    func run(cmd: ParsedCommand, core: CommandCore) {
        if let proj = Helpers.findXcodeProject(FileManager.default.currentDirectoryPath) {
            let schemes = Helpers.findProjectSchemes(proj)
            if schemes.count == 0 {
                if let proj = Helpers.findXcodeProject(FileManager.default.currentDirectoryPath, ignoreWorkspaces: true) {
                    let schemes = Helpers.findProjectSchemes(proj)
                    print("Schemes:")
                    for scheme in schemes.sorted() {
                        print(scheme)
                    }
                }
            } else {
                print("Schemes:")
                for scheme in schemes.sorted() {
                    print(scheme)
                }
            }
        } else {
            print("Could not locate Xcode project/workspace.")
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "schemes"
        command.synopsis = "List project schemes."

        return command
    }
}
