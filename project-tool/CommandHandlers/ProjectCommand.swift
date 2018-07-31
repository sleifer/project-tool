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
    override func run(cmd: ParsedCommand) {
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
