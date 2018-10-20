//
//  main.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/29/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

let toolVersion = "0.1.12"

func main() {
    #if DEBUG
    // for testing in Xcode
    let path = "~/Documents/Code/LogbookVis".expandingTildeInPath
    FileManager.default.changeCurrentDirectoryPath(path)
    #endif

    let core = CommandCore()
    core.set(version: toolVersion)
    core.set(help: "A command-line project tool coordinator.")
    core.set(defaultCommand: "project")

    var root = CommandOption()
    root.shortOption = "-R"
    root.longOption = "--root"
    root.help = "Use git repository root directory, not current."
    core.addGlobal(option: root)

    core.add(command: ProjectCommand.self)
    core.add(command: BuildCommand.self)
    core.add(command: CleanupCommand.self)

    #if DEBUG
    // for testing in Xcode
    let args = ["pt", "cleanup", "-i"]
    #else
    let args = CommandLine.arguments
    #endif

    core.process(args: args)
}

main()
