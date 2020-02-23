//
//  ProjectCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/29/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class ProjectCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var dir = FileManager.default.currentDirectoryPath

        var root = dir
        if let path = Helpers.findGitRoot() {
            root = path
        }

        if cmd.option("--root") != nil {
            dir = root
        }

        if cmd.option("--finder") != nil {
            ProcessRunner.runCommand("open", args: [dir])
        }
        if cmd.option("--launchbar") != nil {
            ProcessRunner.runCommand("open", args: ["-a", "LaunchBar", dir])
        }
        if cmd.option("--sublime") != nil {
            ProcessRunner.runCommand("subl", args: [dir])
        }
        if cmd.option("--bbedit") != nil {
            ProcessRunner.runCommand("bbedit", args: [dir])
        }
        if cmd.option("--tower") != nil {
            if FileManager.default.fileExists(atPath: root.appendingPathComponent(".git")) == true {
                ProcessRunner.runCommand("gittower", args: [root])
            } else {
                print("Current directory is not the root of a git repository.")
            }
        }
        if cmd.option("--xcode") != nil {
            openXcode(dir)
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "project"
        command.synopsis = "Act on project (directory) in various ways."

        var bbedit = CommandOption()
        bbedit.shortOption = "-b"
        bbedit.longOption = "--bbedit"
        bbedit.help = "Open current dir in BBEdit."
        command.options.append(bbedit)

        var finder = CommandOption()
        finder.shortOption = "-f"
        finder.longOption = "--finder"
        finder.help = "Open current dir in Finder."
        command.options.append(finder)

        var launchbar = CommandOption()
        launchbar.shortOption = "-l"
        launchbar.longOption = "--launchbar"
        launchbar.help = "Open current dir in LaunchBar."
        command.options.append(launchbar)

        var sublime = CommandOption()
        sublime.shortOption = "-s"
        sublime.longOption = "--sublime"
        sublime.help = "Open current dir in Sublime Text."
        command.options.append(sublime)

        var tower = CommandOption()
        tower.shortOption = "-t"
        tower.longOption = "--tower"
        tower.help = "Open current dir in Tower."
        command.options.append(tower)

        var xcode = CommandOption()
        xcode.shortOption = "-x"
        xcode.longOption = "--xcode"
        xcode.help = "Open Xcode project from current dir in Xcode."
        command.options.append(xcode)

        return command
    }

    func openXcode(_ dir: String) {
        if let projectPath = Helpers.findXcodeProject(dir) {
            ProcessRunner.runCommand("open", args: [projectPath])
        } else {
            print("No Xcode project in current directory.")
        }
    }
}
