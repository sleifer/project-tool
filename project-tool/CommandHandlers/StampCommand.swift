//
//  StampCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 1/15/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore

class StampCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.parameters.count < 3 {
            print("Missing required parameters.")
            return
        }

        let key = cmd.parameters[0]
        let srcPath = cmd.parameters[1].fullPath
        let dstPath = cmd.parameters[2].fullPath

        if FileManager.default.fileExists(atPath: srcPath) == false {
            print("Source file does not exist.")
            return
        }

        var sha = currentGitHash()
        if isRepositoryDirty() == true {
            sha += "+"
        }

        do {
            let inUrl = URL(fileURLWithPath: srcPath)
            let inData = try Data(contentsOf: inUrl)
            var plist = try PropertyListSerialization.propertyList(from: inData, options: [.mutableContainersAndLeaves], format: nil) as? Dictionary<String, AnyObject>
            plist?[key] = sha as AnyObject
            let outData = try PropertyListSerialization.data(fromPropertyList: plist as Any, format: .xml, options: 0)
            let outUrl = URL(fileURLWithPath: dstPath)
            try outData.write(toFileURL: outUrl)
        } catch {
            print("Error updating plist: \(error)")
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "stamp"
        command.synopsis = "Embed git SHA in Info.plist."
        command.hasFileParameters = true

        var key = ParameterInfo()
        key.hint = "key"
        key.help = "Key to set in plist"
        command.requiredParameters.append(key)

        var src = ParameterInfo()
        src.hint = "src"
        src.help = "Source Info.plist"
        command.requiredParameters.append(src)

        var dst = ParameterInfo()
        dst.hint = "dst"
        dst.help = "Destination Info.plist"
        command.requiredParameters.append(dst)

        return command
    }

    func currentGitHash() -> String {
        let result = ProcessRunner.runCommand(["git", "rev-parse", "--verify", "HEAD"])
        if result.status == 0 {
            return result.stdOut.trimmed()[0..<8]
        }
        return ""
    }

    func isRepositoryDirty() -> Bool {
        let result = ProcessRunner.runCommand(["git", "status"])
        if result.status == 0 {
            if result.stdOut.trimmed().contains("working tree clean") == false {
                return true
            }
        }
        return false
    }
}
