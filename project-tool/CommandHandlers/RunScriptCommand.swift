//
//  RunScriptCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 2/26/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import CommandLineCore
import Foundation
import ProjectWalker

enum RunScriptCommandError: Error {
    case failed(String)
}

let runScriptCatalogURL = URL(fileURLWithPath: "~/.pt-runscript-catalog.json".expandingTildeInPath)

class RunScriptCommand: Command {
    required init() {}

    func run(cmd: ParsedCommand, core: CommandCore) {
        let catalog = RunScriptCatalog.read(contentsOf: runScriptCatalogURL) ?? RunScriptCatalog()

        if cmd.boolOption("--list") {
            let sortedEntries = catalog.entries.sorted()
            let lines = sortedEntries.equalLengthPad(padding: { (entry) -> String in
                entry.name
            }) { (paddedString, entry) -> String in
                "\(paddedString) - \(entry.description)"
            }
            for line in lines {
                print(line)
            }
        } else if cmd.parameters.count == 1 {
            if let entry = catalog.entry(withName: cmd.parameters[0]) {
                if let xcodeProjectPath = Helpers.findXcodeProject(FileManager.default.currentDirectoryPath, ignoreWorkspaces: true) {
                    add(entry: entry, to: xcodeProjectPath)
                } else {
                    print("Can't find an Xcode project to add run script to.")
                }
            } else {
                print("Could not find definition for \(cmd.parameters[0])")
            }
        } else {
            core.parser?.printHelp()
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "runscript"
        command.synopsis = "Helper to add common Run Script build phases to Xcode projects."

        var listCmd = CommandOption()
        listCmd.shortOption = "-l"
        listCmd.longOption = "--list"
        listCmd.help = "List run scripts in the catalog."
        command.options.append(listCmd)

        var dst = ParameterInfo()
        dst.hint = "name"
        dst.help = "Name of run script to add to project"
        dst.completionCallback = { () -> [String] in
            let catalog = RunScriptCatalog.read(contentsOf: runScriptCatalogURL) ?? RunScriptCatalog()
            return catalog.entries.sorted().map { (entry) -> String in
                entry.name
            }
        }
        command.optionalParameters.append(dst)

        return command
    }

    fileprivate func addFiles(_ entry: RunScriptEntry) {
        // files
        let baseUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if let files = entry.files {
            for file in files {
                do {
                    let fileUrl = baseUrl.appendingPathComponent(file.relativePath)
                    try file.contents.write(to: fileUrl, atomically: true, encoding: .utf8)
                    print("Created file '\(file.relativePath)'")
                } catch {
                    print(error)
                }
            }
        }
    }

    // swiftlint:disable cyclomatic_complexity

    fileprivate func addBuildSettings(_ entry: RunScriptEntry, _ nativeTarget: PBXTarget, _ project: XcodeProject) {
        // build settings
        if let buildSettings = entry.buildSettings, let configurations = nativeTarget.getBuildConfigurationList()?.getBuildConfigurations() {
            var needWrite: Bool = false

            for buildSetting in buildSettings {
                var configurationsToEdit = configurations
                if let configurationFilter = buildSetting.configurations {
                    configurationsToEdit = configurationsToEdit.filter({ (config) -> Bool in
                        if let name = config.name, configurationFilter.contains(name) == true {
                            return true
                        }
                        return false
                    })
                }

                for configuration in configurationsToEdit {
                    if configuration.buildSettings == nil {
                        configuration.buildSettings = ProjectFileDictionary()
                        needWrite = true
                    }

                    if let value = buildSetting.value {
                        if configuration.buildSettings?[buildSetting.key] == nil {
                            configuration.buildSettings?[buildSetting.key] = value as AnyObject
                            needWrite = true
                        }
                    } else if let values = buildSetting.values {
                        var array: ProjectFileArray
                        if let value = configuration.buildSettings?[buildSetting.key] as? ProjectFileArray {
                            array = value
                        } else {
                            array = ProjectFileArray()
                            configuration.buildSettings?[buildSetting.key] = array as AnyObject
                            needWrite = true
                        }

                        for value in values {
                            if array.contains(where: { (item) -> Bool in
                                if let itemString = item as? String, itemString == value {
                                    return true
                                }
                                return false
                            }) == false {
                                array.append(value as AnyObject)
                                configuration.buildSettings?[buildSetting.key] = array as AnyObject
                                needWrite = true
                            }
                        }
                    }
                }
            }

            if needWrite == true {
                do {
                    try project.write(to: project.path)
                    print("Added build settings")
                } catch {
                    print(error)
                }
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity

    func add(entry: RunScriptEntry, to projectPath: String) {
        let url = URL(fileURLWithPath: projectPath)
        guard let project = XcodeProject(contentsOf: url) else {
            print("Error: Could not read Xcode project")
            return
        }

        let result = isRunScriptPresent(title: entry.scriptPhaseTitle, project: project)
        guard case let .success(present) = result else {
            if case let .failure(theError) = result {
                print(theError)
            }
            return
        }

        if present == true {
            print("Run script phase '\(entry.name)', titled '\(entry.scriptPhaseTitle)', is already present.")
            return
        }

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            print("Error: Could not read root object")
            return
        }

        guard let nativeTarget = rootObject.getTargets()?.first else {
            print("Error: Could not read native target")
            return
        }

        let newPhase = PBXShellScriptBuildPhase()
        newPhase.buildActionMask = 2147483647
        newPhase.name = entry.scriptPhaseTitle
        newPhase.shellPath = entry.scriptPhaseShell
        newPhase.showEnvVarsInLog = entry.scriptPhaseShowEnv
        newPhase.shellScript = entry.scriptPhaseScript

        project.add(object: newPhase, for: newPhase.referenceKey)
        if let lastNotFirst = entry.lastNotFirst, lastNotFirst == true {
            nativeTarget.buildPhases?.append(newPhase.referenceKey)
        } else {
            nativeTarget.buildPhases?.insert(newPhase.referenceKey, at: 0)
        }

        do {
            try project.write(to: project.path)
            print("Added run script '\(entry.scriptPhaseTitle)'")
        } catch {
            print(error)
        }

        addFiles(entry)

        addBuildSettings(entry, nativeTarget, project)
    }

    func isRunScriptPresent(title: String, project: XcodeProject) -> Result<Bool, RunScriptCommandError> {
        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            return .failure(.failed("Error: Could not read root object"))
        }

        guard let nativeTarget = rootObject.getTargets()?.first else {
            return .failure(.failed("Error: Could not read native target"))
        }

        guard let buildPhases = nativeTarget.getBuildPhases() else {
            return .failure(.failed("Error: Could not read build phases"))
        }

        for phase in buildPhases {
            if let runPhase = phase as? PBXShellScriptBuildPhase {
                if let name = runPhase.name {
                    if name == title {
                        return .success(true)
                    }
                }
            }
        }

        return .success(false)
    }
}
