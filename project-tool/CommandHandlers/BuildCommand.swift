//
//  BuildCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/29/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class BuildCommand: Command {
    var dir = FileManager.default.currentDirectoryPath

    var configurationFlags: [String] = ["-configuration", "Debug"]

    var destinationFlags: [String] = []

    override open func run(cmd: ParsedCommand) {
        if cmd.option("--root") != nil {
            if let path = findGitRoot() {
                dir = path
            } else {
                return
            }
        }

        if cmd.option("--release") != nil {
            configurationFlags = ["-configuration", "Release"]
        }

        var destinationPath = ""
        var dstCount = 0

        if cmd.option("--applications") != nil {
            destinationPath = "/Applications"
            dstCount += 1
        }
        if cmd.option("--bin") != nil {
            destinationPath = "~/bin".expandingTildeInPath
            dstCount += 1
        }
        if cmd.option("--desktop") != nil {
            destinationPath = "~/Desktop".expandingTildeInPath
            dstCount += 1
        }
        if let outOption = cmd.option("--out") {
            destinationPath = outOption.arguments[0]
            dstCount += 1
        }

        if dstCount > 1 {
            print("Only one build destination can be specified.")
            return
        }

        if destinationPath.count != 0 {
            destinationFlags = ["DEPLOYMENT_LOCATION=YES", "DSTROOT=/", "INSTALL_PATH=\(destinationPath)"]
        }

        buildWithXcode()
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

    fileprivate func findWorkspaceScheme(_ projectPath: String) -> String? {
        let proc = ProcessRunner.runCommand("xcodebuild", args: ["-list", "-workspace", projectPath, "-json"])
        if proc.status == 0 {
            let jsonStr = proc.stdOut.trimmed()
            if let jsonData = jsonStr.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    if let root = json as? [String: Any] {
                        if let workspace = root["workspace"] as? [String: Any] {
                            let name = workspace["name"] as? String
                            let schemes = workspace["schemes"] as? [String]

                            if let name = name, let schemes = schemes {
                                if schemes.contains(name) == false {
                                    return schemes[0]
                                } else {
                                    return name
                                }
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
        return nil
    }

    func buildWithXcode() {
        let projectPath = findXcodeProject(dir)
        if projectPath.count == 0 {
            print("No Xcode project in current directory.")
        } else {
            if projectPath.hasSuffix(".xcodeproj") {
                var args: [String] = []
                args.append(contentsOf: configurationFlags)
                args.append(contentsOf: destinationFlags)
                ProcessRunner.runCommand("xcodebuild", args: args, echo: true)
            } else {
                if let scheme = findWorkspaceScheme(projectPath) {
                    var args: [String] = ["-workspace", projectPath, "-scheme", scheme]
                    args.append(contentsOf: configurationFlags)
                    args.append(contentsOf: destinationFlags)
                    print("+++")
                    print("xcodebuild \(args.joined(separator: " "))")
                    print("---")
                    ProcessRunner.runCommand("xcodebuild", args: args, echo: true)
                }
            }
            let buildDir = projectPath.deletingLastPathComponent.appendingPathComponent("build")
            let dfm = FileManager.default
            if dfm.fileExists(atPath: buildDir) == true {
                do {
                    try dfm.removeItem(atPath: buildDir)
                } catch {
                }
            }
        }
    }
}
