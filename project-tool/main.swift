//
//  main.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/29/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

let toolVersion = "0.1.6"
var baseDirectory: String = ""
var commandName: String = ""

func main() {
    autoreleasepool {
        let parser = ArgParser(definition: makeCommandDefinition())

        do {
            #if DEBUG
            let args = ["pt", "cleanup"]
            commandName = args[0]
            let parsed = try parser.parse(args)
            #else
            let parsed = try parser.parse(CommandLine.arguments)
            commandName = CommandLine.arguments[0].lastPathComponent
            #endif

            #if DEBUG
            // for testing in Xcode
            let path = "~/Documents/Code/project-tool".expandingTildeInPath
            FileManager.default.changeCurrentDirectoryPath(path)
            #endif

            baseDirectory = FileManager.default.currentDirectoryPath

            if let cmd = commandFrom(parser: parser) {
                cmd.run(cmd: parsed)
            }
        } catch {
            print("Invalid arguments.")
            parser.printHelp()
        }

        CommandLineRunLoop.shared.waitForBackgroundTasks()
    }
}

// swiftlint:disable cyclomatic_complexity

func commandFrom(parser: ArgParser) -> Command? {
    var skipSubcommand = false
    var cmd: Command?
    let parsed = parser.parsed

    if parsed.option("--version") != nil {
        print("Version \(toolVersion)")
        skipSubcommand = true
    }
    if parsed.option("--help") != nil {
        parser.printHelp()
        skipSubcommand = true
    }

    if skipSubcommand == false {
        switch parsed.subcommand ?? "root" {
        case "bashcomp":
            cmd = BashcompCommand(parser: parser)
        case "bashcompfile":
            cmd = BashcompfileCommand()
        case "project":
            cmd = ProjectCommand()
        case "build":
            cmd = BuildCommand()
        case "cleanup":
            cmd = CleanupCommand()
        case "root":
            if parsed.parameters.count > 0 {
                print("Unknown command: \(parsed.parameters[0])")
            }
        default:
            print("Unknown command.")
        }
    }

    return cmd
}

// swiftlint:enable cyclomatic_complexity

func baseSubPath(_ subpath: String) -> String {
    var path = subpath.standardizingPath
    if path.isAbsolutePath == false {
        path = baseDirectory.appendingPathComponent(path)
    }
    return path
}

func setCurrentDir(_ subpath: String) {
    FileManager.default.changeCurrentDirectoryPath(baseSubPath(subpath))
}

func resetCurrentDir() {
    setCurrentDir(baseDirectory)
}

main()
