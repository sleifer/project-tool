//
//  CommandDefinition.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

func makeCommandDefinition() -> CommandDefinition {
    var definition = CommandDefinition()
    definition.help = "A command-line project tool coordinator."

    var version = CommandOption()
    version.longOption = "--version"
    version.help = "Show tool version information"
    definition.options.append(version)

    var help = CommandOption()
    help.shortOption = "-h"
    help.longOption = "--help"
    help.help = "Show this help"
    definition.options.append(help)

    var root = CommandOption()
    root.shortOption = "-r"
    root.longOption = "--root"
    root.help = "Use git repository root directory, not current."
    definition.options.append(root)

    definition.subcommands.append(projectCommand())
    definition.subcommands.append(buildCommand())
    definition.subcommands.append(bashcompCommand())
    definition.subcommands.append(bashcompfileCommand())

    definition.defaultSubcommand = "project"

    return definition
}

private func projectCommand() -> SubcommandDefinition {
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

private func buildCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "build"
    command.synopsis = "Build project in various ways."

    var release = CommandOption()
    release.shortOption = "-R"
    release.longOption = "--release"
    release.help = "Build Release instead of Debug."
    command.options.append(release)

    var inApp = CommandOption()
    inApp.shortOption = "-A"
    inApp.longOption = "--applications"
    inApp.help = "Build into /Applications."
    command.options.append(inApp)

    var inBin = CommandOption()
    inBin.shortOption = "-B"
    inBin.longOption = "--bin"
    inBin.help = "Build into ~/bin."
    command.options.append(inBin)

    var inDesk = CommandOption()
    inDesk.shortOption = "-D"
    inDesk.longOption = "--desktop"
    inDesk.help = "Build into ~/Desktop."
    command.options.append(inDesk)

    var inPassed = CommandOption()
    inPassed.shortOption = "-O"
    inPassed.longOption = "--out"
    inPassed.argumentCount = 1
    inPassed.hasFileArguments = true
    inPassed.help = "Build into <param>."
    command.options.append(inPassed)

    return command
}

private func bashcompCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "bashcomp"
    command.hidden = true
    command.suppressesOptions = true
    command.warnOnMissingSpec = false

    return command
}

private func bashcompfileCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "bashcompfile"
    command.hidden = true
    command.warnOnMissingSpec = false

    return command
}
