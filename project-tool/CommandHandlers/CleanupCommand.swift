//
//  CleanupCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 8/20/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class CleanupCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var derived: Bool = false
        var realm: Bool = false

        if cmd.option("--derived") != nil {
            derived = true
        }
        if cmd.option("--realm") != nil {
            realm = true
        }
        if derived == false && realm == false {
            derived = true
            realm = true
        }

        if derived == true {
            print("Deleting DerivedData...")
            let derivedDataPath = "~/Library/Developer/Xcode/DerivedData".expandingTildeInPath
            ProcessRunner.runCommand("rm", args: ["-rf", derivedDataPath])
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

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "cleanup"
        command.synopsis = "Delete build products."

        var derived = CommandOption()
        derived.shortOption = "-d"
        derived.longOption = "--derived"
        derived.help = "Delete derived data."
        command.options.append(derived)

        var realm = CommandOption()
        realm.shortOption = "-r"
        realm.longOption = "--realm"
        realm.help = "Delete Realm sync_bin."
        command.options.append(realm)

        return command
    }
}