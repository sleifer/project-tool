//
//  ReadmeCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 4/9/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Foundation

import CommandLineCore

class ReadmeCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        let fmd = FileManager.default
        let curDir = fmd.currentDirectoryPath
        let mdPath = curDir.appendingPathComponent("README.md")
        let pdfPath = curDir.appendingPathComponent("README.pdf")
        let htmlPath = curDir.appendingPathComponent("README.html")

        if cmd.option("--edit") != nil {
            if fmd.fileExists(atPath: mdPath) == true {
                ProcessRunner.runCommand("open '\(mdPath)'")
            } else {
                print("Missing README.md")
            }
        } else {
            if fmd.fileExists(atPath: pdfPath) == true {
                ProcessRunner.runCommand("open '\(pdfPath)'")
            } else if fmd.fileExists(atPath: htmlPath) == true {
                ProcessRunner.runCommand("open '\(htmlPath)'")
            } else if fmd.fileExists(atPath: mdPath) == true {
                ProcessRunner.runCommand("open '\(mdPath)'")
            } else {
                print("Missing README.md, README.pdf, and README.html")
            }
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "readme"
        command.synopsis = "View (or edit) README.html, README.pdf, README.md."

        var finder = CommandOption()
        finder.shortOption = "-e"
        finder.longOption = "--edit"
        finder.help = "Edit README.md instead of viewing README."
        command.options.append(finder)

        return command
    }

}
