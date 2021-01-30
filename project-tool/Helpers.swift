//
//  Helpers.swift
//  project-tool
//
//  Created by Simeon Leifer on 1/25/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import CommandLineCore
import Foundation
import AppKit

class Helpers {
    static func findGitRoot() -> String? {
        let proc = ProcessRunner.runCommand("git", args: ["rev-parse", "--show-toplevel"])
        if proc.status == 0 {
            return proc.stdOut.trimmed()
        } else {
            print(proc.stdErr)
        }
        return nil
    }

    static func findRunningXcode() -> String? {
        let xcodes = NSWorkspace.shared.runningApplications.filter { (item) -> Bool in
            item.bundleIdentifier == "com.apple.dt.Xcode"
        }
        if let item = xcodes.first {
            return item.bundleURL?.path
        }
        return nil
    }

    static func findXcodeProject(_ url: URL, ignoreWorkspaces: Bool = false) -> String? {
        return findXcodeProject(url.path, ignoreWorkspaces: ignoreWorkspaces)
    }

    static func findXcodeProject(_ path: String, ignoreWorkspaces: Bool = false) -> String? {
        var projectDir: String?

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            for file in contents {
                if projectDir == nil, file.hasSuffix(".xcodeproj") == true {
                    projectDir = path.appendingPathComponent(file)
                }
                if ignoreWorkspaces == false, file.hasSuffix(".xcworkspace") == true {
                    projectDir = path.appendingPathComponent(file)
                }
            }
        } catch {
            print(error)
        }

        return projectDir
    }

    static func getProjectInfo(_ projectPath: String) -> XcodebuildList? {
        let isWorkspace: Bool
        if projectPath.hasSuffix(".xcodeproj") == true {
            isWorkspace = false
        } else {
            isWorkspace = true
        }

        let proc: ProcessRunner
        if isWorkspace == false {
            proc = ProcessRunner.runCommand("xcodebuild", args: ["-list", "-project", projectPath, "-json"])
        } else {
            proc = ProcessRunner.runCommand("xcodebuild", args: ["-list", "-workspace", projectPath, "-json"])
        }
        if proc.status == 0 {
            let jsonStr = proc.stdOut.trimmed()
            if let jsonData = jsonStr.data(using: .utf8) {
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(XcodebuildList.self, from: jsonData)
                } catch {
                    print("Error loading: \(error)")
                }
            }
        }
        return nil
    }

    static func findWorkspaceScheme(_ projectPath: String) -> String? {
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

    static func findProjectTargets(_ projectPath: String) -> [String] {
        let proc = ProcessRunner.runCommand("xcodebuild", args: ["-list", "-project", projectPath, "-json"])
        if proc.status == 0 {
            let jsonStr = proc.stdOut.trimmed()
            if let jsonData = jsonStr.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    if let root = json as? [String: Any] {
                        if let workspace = root["project"] as? [String: Any] {
                            let targets = workspace["targets"] as? [String]

                            if let targets = targets {
                                return targets
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
        return []
    }

    static func findProjectSchemes(_ projectPath: String) -> [String] {
        let proc = ProcessRunner.runCommand("xcodebuild", args: ["-list", "-project", projectPath, "-json"])
        if proc.status == 0 {
            let jsonStr = proc.stdOut.trimmed()
            if let jsonData = jsonStr.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    if let root = json as? [String: Any] {
                        if let workspace = root["project"] as? [String: Any] {
                            let schemes = workspace["schemes"] as? [String]

                            if let schemes = schemes {
                                return schemes
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
        return []
    }

    static func findWorkspaceSchemes(_ projectPath: String) -> [String] {
        let proc = ProcessRunner.runCommand("xcodebuild", args: ["-list", "-workspace", projectPath, "-json"])
        if proc.status == 0 {
            let jsonStr = proc.stdOut.trimmed()
            if let jsonData = jsonStr.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    if let root = json as? [String: Any] {
                        if let workspace = root["workspace"] as? [String: Any] {
                            let schemes = workspace["schemes"] as? [String]

                            if let schemes = schemes {
                                return schemes
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
        return []
    }

    static func findDstBinaryPath(_ args: [String]) -> String? {
        var targetBuildDir: String?
        var executableName: String?
        var envargs = args
        envargs.append("-showBuildSettings")
        let runner = ProcessRunner.runCommand(envargs)
        if runner.status == 0 {
            let lines = runner.stdOut.trimmed().lines()
            for line in lines {
                let trimLine = line.trimmed()
                if trimLine.hasPrefix("TARGET_BUILD_DIR") {
                    let parts = trimLine.components(separatedBy: " = ")
                    if parts.count == 2 {
                        targetBuildDir = parts[1].trimmed()
                    }
                } else if trimLine.hasPrefix("FULL_PRODUCT_NAME") {
                    let parts = trimLine.components(separatedBy: " = ")
                    if parts.count == 2 {
                        executableName = parts[1].trimmed()
                    }
                }
            }
        }
        if let theTargetBuildDir = targetBuildDir, let theExecutableName = executableName {
            return theTargetBuildDir.appendingPathComponent(theExecutableName)
        }

        return nil
    }
}

class XcodebuildList: Codable {
    var project: Project?
    var workspace: Workspace?

    var name: String {
        return project?.name ?? workspace?.name ?? ""
    }

    var schemes: [String] {
        return project?.schemes ?? workspace?.schemes ?? []
    }

    class Project: Codable {
        var configurations: [String]
        var name: String
        var schemes: [String]
        var targets: [String]
    }

    class Workspace: Codable {
        var name: String
        var schemes: [String]
    }
}
