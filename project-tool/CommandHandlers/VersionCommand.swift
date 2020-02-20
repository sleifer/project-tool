//
//  VersionCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 1/14/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore
import ProjectWalker

enum VersionCommandError: Error {
    case failed(String)
}

enum VersionSystemState {
    case unknown
    case genericPresent
    case appleGenericPresent
    case genericReady
    case appleGenericReady
}

enum RunScriptState {
    case unknown
    case present
    case ready
}

enum DerivedSourceState {
    case unknown
    case present
    case ready
}

class VersionCommand: Command {
    var baseDirUrl: URL?

    var xcodeProjectUrl: URL?
    var versionsStateFileUrl: URL?
    var project: XcodeProject?
    var configurations: [XCBuildConfiguration]?
    var infoPlistFileUrl: URL?
    var versionSystemState: VersionSystemState = .unknown
    var marketingVersion: String = "1.0"
    var projectVersion: String = "1"
    var runScriptState: RunScriptState = .unknown
    var derivedSourceState: DerivedSourceState = .unknown

    required init() {}

    func run(cmd: ParsedCommand, core: CommandCore) {
        var dir = FileManager.default.currentDirectoryPath

        if cmd.boolOption("--root") == true {
            if let path = Helpers.findGitRoot() {
                dir = path
            } else {
                print("Could not find git root")
                return
            }
        }

        baseDirUrl = URL(fileURLWithPath: dir)

        if cmd.boolOption("--init") == true {
            doInit()
            return
        }

        var handled: Bool = false

        if cmd.boolOption("--bump") == true {
            handled = true
            bumpProjectVersion()
        } else if let cmd = cmd.option("--bundle") {
            handled = true
            setProjectVersion(cmd.arguments[0])
        }

        if let cmd = cmd.option("--marketing") {
            handled = true
            setMarketingVersion(cmd.arguments[0])
        }

        if handled == false {
            reportVersions()
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "version"
        command.synopsis = "AGV helpers."

        var initCmd = CommandOption()
        initCmd.longOption = "--init"
        initCmd.help = "Initialize versioning support."
        command.options.append(initCmd)

        var bumpCmd = CommandOption()
        bumpCmd.shortOption = "-b"
        bumpCmd.longOption = "--bump"
        bumpCmd.help = "Bump version."
        command.options.append(bumpCmd)

        var versionCmd = CommandOption()
        versionCmd.shortOption = "-s"
        versionCmd.longOption = "--bundle"
        versionCmd.argumentCount = 1
        versionCmd.help = "Set bundle version."
        command.options.append(versionCmd)

        var marketingCmd = CommandOption()
        marketingCmd.shortOption = "-m"
        marketingCmd.longOption = "--marketing"
        marketingCmd.argumentCount = 1
        marketingCmd.help = "Set marketing version"
        command.options.append(marketingCmd)

        return command
    }

    func bumpProjectVersion() {
        do {
            try locateFiles()
            try determineVersionState()

            switch versionSystemState {
            case .unknown:
                print("Version unknown")
            case .genericPresent:
                print("Generic Versioning")
                projectVersion = String((Int(projectVersion) ?? 0) + 1)
                print("projectVersion = \(projectVersion)")
                try writeGenericVersion()
            case .appleGenericPresent:
                print("Apple Generic Versioning")
                projectVersion = String((Int(projectVersion) ?? 0) + 1)
                print("projectVersion = \(projectVersion)")
                try writeAppleGenericVersion()
            case .genericReady:
                print("Generic Versioning not set up")
            case .appleGenericReady:
                print("Apple Generic Versioning not set up")
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    func setProjectVersion(_ newVersion: String) {
        do {
            try locateFiles()
            try determineVersionState()

            switch versionSystemState {
            case .unknown:
                print("Version unknown")
            case .genericPresent:
                print("Generic Versioning")
                projectVersion = newVersion
                print("projectVersion = \(projectVersion)")
                try writeGenericVersion()
            case .appleGenericPresent:
                print("Apple Generic Versioning")
                projectVersion = newVersion
                print("projectVersion = \(projectVersion)")
                try writeAppleGenericVersion()
            case .genericReady:
                print("Generic Versioning not set up")
            case .appleGenericReady:
                print("Apple Generic Versioning not set up")
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    func setMarketingVersion(_ newVersion: String) {
        do {
            try locateFiles()
            try determineVersionState()

            switch versionSystemState {
            case .unknown:
                print("Version unknown")
            case .genericPresent:
                print("Generic Versioning")
                marketingVersion = newVersion
                print("marketingVersion = \(marketingVersion)")
                try writeGenericVersion()
            case .appleGenericPresent:
                print("Apple Generic Versioning")
                marketingVersion = newVersion
                print("marketingVersion = \(marketingVersion)")
                try writeAppleGenericVersion()
            case .genericReady:
                print("Generic Versioning not set up")
            case .appleGenericReady:
                print("Apple Generic Versioning not set up")
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    func reportVersions() {
        do {
            try locateFiles()
            try determineVersionState()

            switch versionSystemState {
            case .unknown:
                print("Version unknown")
            case .genericPresent:
                print("Generic Versioning")
                print("Marketing Version:")
                print(marketingVersion)
                print("Project Version:")
                print(projectVersion)
            case .appleGenericPresent:
                print("Apple Generic Versioning")
                print("Marketing Version:")
                print(marketingVersion)
                print("Project Version:")
                print(projectVersion)
            case .genericReady:
                print("Generic Versioning not set up")
            case .appleGenericReady:
                print("Apple Generic Versioning not set up")
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    func doInit() {
        do {
            try locateFiles()
            try determineVersionState()
            try determineRunScriptState()
            try determineDerivedSourceState()

            if versionSystemState == .unknown {
                throw VersionCommandError.failed("Error: Could not determine version system state.")
            }
            if runScriptState == .unknown {
                throw VersionCommandError.failed("Error: Could not determine run script state.")
            }
            if derivedSourceState == .unknown {
                throw VersionCommandError.failed("Error: Could not determine derived source state.")
            }

            try actOnVersionState()
            try actOnRunScriptState()
            try actOnDerivedSourceState()
        } catch {
            print("Exception: \(error)")
        }

        print("Done.")
    }

    func actOnVersionState() throws {
        switch versionSystemState {
        case .unknown:
            throw VersionCommandError.failed("Error: Could not determine version system state.")
        case .genericPresent:
            print("Generic version system set up.")
        case .appleGenericPresent:
            print("Apple Generic version system set up.")
        case .genericReady:
            print("Setting up Generic version system.")
            try setupGeneric()
        case .appleGenericReady:
            print("Setting up Apple Generic version system.")
            try setupAppleGeneric()
        }
    }

    func actOnRunScriptState() throws {
        switch runScriptState {
        case .unknown:
            throw VersionCommandError.failed("Error: Could not determine run script state.")
        case .present:
            print("Run script phase is set up.")
        case .ready:
            print("Setting up run script phase.")
            try setupRunScript()
        }
    }

    func actOnDerivedSourceState() throws {
        switch derivedSourceState {
        case .unknown:
            throw VersionCommandError.failed("Error: Could not determine derived source state.")
        case .present:
            print("Derived Source is set up.")
        case .ready:
            print("Setting up derived source.")
            try setupDerivedSource()
        }
    }

    func setupGeneric() throws {
        try writeGenericVersion()
    }

    func setupAppleGeneric() throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }
        guard let configurations = self.configurations else {
            throw VersionCommandError.failed("Error: configurations not set")
        }
        guard let infoPlistFileUrl = self.infoPlistFileUrl else {
            throw VersionCommandError.failed("Error: infoPlistFileUrl not set")
        }

        for configuration in configurations {
            configuration.buildSettings?["VERSIONING_SYSTEM"] = "apple-generic" as AnyObject
            configuration.buildSettings?["MARKETING_VERSION"] = marketingVersion as AnyObject
            configuration.buildSettings?["CURRENT_PROJECT_VERSION"] = projectVersion as AnyObject
        }

        try project.write(to: project.path)

        let data = try Data(contentsOf: infoPlistFileUrl)
        var plist = try PropertyListSerialization.propertyList(from: data, options: [.mutableContainersAndLeaves], format: nil) as? [String: Any]
        plist?["CFBundleShortVersionString"] = "$(MARKETING_VERSION)"
        plist?["CFBundleVersion"] = "$(CURRENT_PROJECT_VERSION)"
        let outData = try PropertyListSerialization.data(fromPropertyList: plist as Any, format: .xml, options: 0)
        try outData.write(toFileURL: infoPlistFileUrl)
    }

    func determineRunScriptState() throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            throw VersionCommandError.failed("Error: Could not read root object")
        }

        guard let nativeTarget = rootObject.getTargets()?.first else {
            throw VersionCommandError.failed("Error: Could not read native target")
        }

        guard let buildPhases = nativeTarget.getBuildPhases() else {
            throw VersionCommandError.failed("Error: Could not read build phases")
        }

        for phase in buildPhases {
            if let runPhase = phase as? PBXShellScriptBuildPhase {
                if let script = runPhase.shellScript {
                    if script.contains("pt stamp") == true {
                        runScriptState = .present
                        return
                    }
                }
            }
        }

        runScriptState = .ready
    }

    // swiftlint:disable cyclomatic_complexity

    func determineDerivedSourceState() throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            throw VersionCommandError.failed("Error: Could not read root object")
        }

        guard let mainGroup = rootObject.getMainGroup() else {
            throw VersionCommandError.failed("Error: Could not read main group")
        }

        derivedSourceState = .ready

        var derivedGroup: PBXGroup?
        var groupQueue: [PBXGroup] = [mainGroup]

        while let group = groupQueue.first {
            groupQueue.removeFirst()
            if group.sourceTree == "BUILT_PRODUCTS_DIR", group.path == nil {
                derivedGroup = group
                break
            }
            if let groupChildren = group.getChildren()?.compactMap({ (element) -> PBXGroup? in
                element as? PBXGroup
            }) {
                groupQueue.append(contentsOf: groupChildren)
            }
        }

        guard let theDerivedGroup = derivedGroup else {
            return
        }

        var versionsFileReference: PBXFileReference?

        if let childFiles = theDerivedGroup.getChildren()?.compactMap({ (element) -> PBXFileReference? in
            element as? PBXFileReference
        }) {
            for childFile in childFiles {
                if childFile.path == "versions.swift", childFile.name == nil {
                    versionsFileReference = childFile
                    break
                }
            }
        }

        guard let theVersionsFileReference = versionsFileReference else {
            return
        }

        guard let nativeTarget = rootObject.getTargets()?.first else {
            return
        }

        guard let buildPhases = nativeTarget.getBuildPhases() else {
            return
        }

        for phase in buildPhases {
            if let sourcesPhase = phase as? PBXSourcesBuildPhase {
                if let files = sourcesPhase.getFiles() {
                    for file in files {
                        let fileRef = file.getFileRef()
                        if fileRef == theVersionsFileReference {
                            derivedSourceState = .present
                            return
                        }
                    }
                }
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity

    func setupRunScript() throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            throw VersionCommandError.failed("Error: Could not read root object")
        }

        guard let nativeTarget = rootObject.getTargets()?.first else {
            throw VersionCommandError.failed("Error: Could not read native target")
        }

        let stampPhase = PBXShellScriptBuildPhase()
        stampPhase.buildActionMask = 2147483647
        stampPhase.outputPaths = ["$(BUILT_PRODUCTS_DIR)/versions.swift"]
        stampPhase.name = "Stamp Version"
        stampPhase.shellPath = "/bin/sh"
        stampPhase.showEnvVarsInLog = false
        stampPhase.shellScript = """
        PATH=${PATH}:${HOME}/bin
        if which pt > /dev/null; then
          pt stamp ${BUILT_PRODUCTS_DIR}/versions.swift
        else
          echo "warning: pt not installed"
        fi
        """

        project.add(object: stampPhase, for: stampPhase.referenceKey)
        nativeTarget.buildPhases?.insert(stampPhase.referenceKey, at: 0)

        try project.write(to: project.path)
    }

    // swiftlint:disable cyclomatic_complexity

    func setupDerivedSource() throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            throw VersionCommandError.failed("Error: Could not read root object")
        }

        guard let mainGroup = rootObject.getMainGroup() else {
            throw VersionCommandError.failed("Error: Could not read main group")
        }

        var derivedGroup: PBXGroup?
        var groupQueue: [PBXGroup] = [mainGroup]

        while let group = groupQueue.first {
            groupQueue.removeFirst()
            if group.sourceTree == "BUILT_PRODUCTS_DIR", group.path == nil {
                derivedGroup = group
                break
            }
            if let groupChildren = group.getChildren()?.compactMap({ (element) -> PBXGroup? in
                element as? PBXGroup
            }) {
                groupQueue.append(contentsOf: groupChildren)
            }
        }

        if derivedGroup == nil {
            let group = PBXGroup()
            group.name = "Derived"
            group.children = []
            group.sourceTree = "BUILT_PRODUCTS_DIR"
            project.add(object: group, for: group.referenceKey)
            mainGroup.children?.insert(group.referenceKey, at: 0)
            derivedGroup = group
        }

        guard let theDerivedGroup = derivedGroup else {
            return
        }

        var versionsFileReference: PBXFileReference?

        if let childFiles = theDerivedGroup.getChildren()?.compactMap({ (element) -> PBXFileReference? in
            element as? PBXFileReference
        }) {
            for childFile in childFiles {
                if childFile.path == "versions.swift", childFile.name == nil {
                    versionsFileReference = childFile
                    break
                }
            }
        }

        if versionsFileReference == nil {
            let fileReference = PBXFileReference()
            fileReference.fileEncoding = 4
            fileReference.lastKnownFileType = "sourcecode.swift"
            fileReference.path = "versions.swift"
            fileReference.sourceTree = "<group>"
            project.add(object: fileReference, for: fileReference.referenceKey)
            theDerivedGroup.children?.append(fileReference.referenceKey)
            versionsFileReference = fileReference
        }

        guard let theVersionsFileReference = versionsFileReference else {
            return
        }

        guard let nativeTarget = rootObject.getTargets()?.first else {
            return
        }

        let sourcesPhase = nativeTarget.getBuildPhases()?.filter({ (phase) -> Bool in
            if phase is PBXSourcesBuildPhase {
                return true
            }
            return false
            }).first

        if let theSourcesPhase = sourcesPhase {
            var found: Bool = false
            if let files = theSourcesPhase.getFiles() {
                for file in files {
                    let fileRef = file.getFileRef()
                    if fileRef == theVersionsFileReference {
                        found = true
                        break
                    }
                }
            }
            if found == false {
                let buildFile = PBXBuildFile()
                buildFile.fileRef = theVersionsFileReference.referenceKey
                project.add(object: buildFile, for: buildFile.referenceKey)
                theSourcesPhase.files?.append(buildFile.referenceKey)
            }
        }

        try project.write(to: project.path)
    }

    // swiftlint:enable cyclomatic_complexity

    func writeGenericVersion() throws {
        guard let versionsStateFileUrl = self.versionsStateFileUrl else {
            throw VersionCommandError.failed("Error: versionsStateFileUrl not set")
        }

        let state = GenericVersionState(marketing: marketingVersion, project: projectVersion)
        state.save(toURL: versionsStateFileUrl)
    }

    func writeAppleGenericVersion() throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }
        guard let configurations = self.configurations else {
            throw VersionCommandError.failed("Error: configurations not set")
        }

        for configuration in configurations {
            configuration.buildSettings?["MARKETING_VERSION"] = marketingVersion as AnyObject
            configuration.buildSettings?["CURRENT_PROJECT_VERSION"] = projectVersion as AnyObject
        }

        try project.write(to: project.path)
    }

    func primaryConfiguration() -> XCBuildConfiguration? {
        let primaryConfigurationOptional = configurations?.first { (config) -> Bool in
            config.name == "Release"
        } ?? configurations?.first

        return primaryConfigurationOptional
    }

    func determineVersionState() throws {
        if versionSystemState != .unknown {
            // already run, move on
            return
        }

        guard let versionsStateFileUrl = self.versionsStateFileUrl else {
            throw VersionCommandError.failed("Error: versionsStateFileUrl not set")
        }

        guard let primaryConfiguration = primaryConfiguration() else {
            throw VersionCommandError.failed("Error: Could not read configurations")
        }

        if FileManager.default.fileExists(atPath: versionsStateFileUrl.path) == true {
            // generic system present
            versionSystemState = .genericPresent

            if let state = GenericVersionState.load(fromURL: versionsStateFileUrl) {
                marketingVersion = state.marketingVersion
                projectVersion = state.projectVersion
            }
        } else if primaryConfiguration.buildSettings?.string(forKey: "VERSIONING_SYSTEM") == "apple-generic", let marketingVersion = primaryConfiguration.buildSettings?.string(forKey: "MARKETING_VERSION"), let projectVersion = primaryConfiguration.buildSettings?.string(forKey: "CURRENT_PROJECT_VERSION") {
            // apple generic system present
            versionSystemState = .appleGenericPresent
            self.marketingVersion = marketingVersion
            self.projectVersion = projectVersion
        } else if let plistPath = primaryConfiguration.buildSettings?.string(forKey: "INFOPLIST_FILE"), plistPath.count > 0 {
            // apple generic system ready
            versionSystemState = .appleGenericReady
            infoPlistFileUrl = xcodeProjectUrl?.deletingLastPathComponent().appendingPathComponent(plistPath)

            if let listUrl = infoPlistFileUrl {
                try determineVersionsFrom(plist: listUrl)
            }
        } else {
            // generic system ready
            versionSystemState = .genericReady
        }
    }

    func determineVersionsFrom(plist listUrl: URL) throws {
        let data = try Data(contentsOf: listUrl)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        if let info = plist as? [String: Any] {
            if let version = info["CFBundleShortVersionString"] as? String {
                marketingVersion = version
            }
            if let build = info["CFBundleVersion"] as? String {
                projectVersion = build
            }
        }
    }

    func locateFiles() throws {
        if xcodeProjectUrl != nil, project != nil, configurations != nil, versionsStateFileUrl != nil {
            // already run, move on
            return
        }

        guard let baseDirUrl = self.baseDirUrl else {
            throw VersionCommandError.failed("Error: baseDirUrl not set")
        }

        guard let projectPath = Helpers.findXcodeProject(baseDirUrl, ignoreWorkspaces: true) else {
            throw VersionCommandError.failed("Error: Could not find Xcode project")
        }

        let url = URL(fileURLWithPath: projectPath)
        xcodeProjectUrl = url
        guard let project = XcodeProject(contentsOf: url) else {
            throw VersionCommandError.failed("Error: Could not read Xcode project")
        }
        self.project = project

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            throw VersionCommandError.failed("Error: Could not read root object")
        }

        guard let nativeTarget = rootObject.getTargets()?.first else {
            throw VersionCommandError.failed("Error: Could not read native target")
        }

        guard let configurations = nativeTarget.getBuildConfigurationList()?.getBuildConfigurations(), configurations.count > 0 else {
            throw VersionCommandError.failed("Error: Could not read configurations")
        }
        self.configurations = configurations

        versionsStateFileUrl = baseDirUrl.appendingPathComponent("versions.json")
    }
}
