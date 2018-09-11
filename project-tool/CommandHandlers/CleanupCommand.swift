//
//  CleanupCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 8/20/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

enum SubmoduleParseRegex: Int {
    case whole = 0
    case sha
    case pathRoot
    case name
    case version
    case count

    static func pattern() -> String {
        return "[ +]([0-9a-f]+) ((?:[^ /]+/)*)?([^ /]+)+ \\((.*)\\)"
    }
}

class CleanupCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var derived: Bool = false
        var ignored: Bool = false
        var realm: Bool = false

        if cmd.option("--derived") != nil {
            derived = true
        }
        if cmd.option("--ignored") != nil {
            ignored = true
        }
        if cmd.option("--realm") != nil {
            realm = true
        }
        if derived == false && ignored == false && realm == false {
            derived = true
            ignored = true
            realm = true
        }

        if derived == true {
            print("Deleting DerivedData...")
            let derivedDataPath = "~/Library/Developer/Xcode/DerivedData".expandingTildeInPath
            ProcessRunner.runCommand("rm", args: ["-rf", derivedDataPath])
        }

        if ignored == true {
            print("Deleting files matching in gitignore...")
            var paths: [String] = []
            gatherIgnoredFiles(in: ".", paths: &paths, core: core)
            for path in paths {
                ProcessRunner.runCommand("rm", args: ["-rf", path])
            }
        }

        if realm == true {
            print("Deleting Realm sync_bin...")
            if let tmpDir = ProcessInfo.processInfo.environment["TMPDIR"] {
                FileManager.default.changeCurrentDirectoryPath(tmpDir)
                ProcessRunner.runCommand("rm", args: ["-r", "sync_bin"])
            }
        }

        print("Done.")
    }

    func gatherIgnoredFiles(in dir: String, paths: inout [String], core: CommandCore) {
        core.setCurrentDir(core.baseSubPath(dir))
        // get status including ignored files
        let runner = ProcessRunner.runCommand("git", args: ["status", "--ignored", "--short"])
        // filter down to ignored files, transforming to paths including 'dir'
        let lines = runner.stdOut.lines().filter { (text) -> Bool in
            return text.hasPrefix("!! ") == true && text.contains(".xcodeproj") == false && text.contains(".xcworkspace") == false
            }.map { (text) -> String in
                return dir.appendingPathComponent(text.suffix(from: 3))
        }
        paths.append(contentsOf: lines)

        // get submodules
        let runner2 = ProcessRunner.runCommand("git", args: ["submodule"])
        let text = runner2.stdOut
        var modules: [String] = []
        let matches = text.regex(SubmoduleParseRegex.pattern())
        for match in matches {
            if match.count == SubmoduleParseRegex.count.rawValue {
                let path = match[SubmoduleParseRegex.pathRoot.rawValue] + match[SubmoduleParseRegex.name.rawValue]
                modules.append(path)
            }
        }
        modules = modules.map({ (text) -> String in
            return dir.appendingPathComponent(text)
        })

        core.resetCurrentDir()

        for aModule in modules {
            gatherIgnoredFiles(in: aModule, paths: &paths, core: core)
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "cleanup"
        command.synopsis = "Delete build products."

        var derived = CommandOption()
        derived.shortOption = "-d"
        derived.longOption = "--derived"
        derived.help = "Delete derived data."
        command.options.append(derived)

        var ignored = CommandOption()
        ignored.shortOption = "-i"
        ignored.longOption = "--ignore"
        ignored.help = "Delete files matched by gitignore."
        command.options.append(ignored)

        var realm = CommandOption()
        realm.shortOption = "-r"
        realm.longOption = "--realm"
        realm.help = "Delete Realm sync_bin."
        command.options.append(realm)

        return command
    }
}
