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

        if cmd.option("--root") != nil {
            if let path = findGitRoot() {
                dir = path
            } else {
                return
            }
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
        if cmd.option("--tower") != nil {
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent(".git")) == true {
                ProcessRunner.runCommand("gittower", args: [dir])
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

    func findGitRoot() -> String? {
        let proc = ProcessRunner.runCommand("git", args: ["rev-parse", "--show-toplevel"])
        if proc.status == 0 {
            return proc.stdOut.trimmed()
        } else {
            print(proc.stdErr)
        }
        return nil
    }

    func openXcode(_ dir: String) {
        let projectPath = findXcodeProject(dir)
        if projectPath.count == 0 {
            print("No Xcode project in current directory.")
        } else {
            ProcessRunner.runCommand("open", args: [projectPath])
        }
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
}
