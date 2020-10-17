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
    var targets: [NativeTargetWithConfigurations] = []
    var targetFilter: [String] = []

    required init() {}

    // swiftlint:disable cyclomatic_complexity

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

        targetFilter = cmd.parameters

        if cmd.boolOption("--init") == true {
            let agvonly = cmd.boolOption("--agvonly")
            doInit(agvonly)
            return
        }

        var handled: Bool = false

        var log: [[String]] = []

        do {
            try locateFiles()
            for target in targets {
                if targetFilter.count == 0 || targetFilter.contains(target.target.openStepComment) == true {
                    log.append([])
                }
            }
        } catch {}

        if cmd.boolOption("--bump") == true {
            handled = true
            bumpProjectVersion(log: &log)
        } else if let cmd = cmd.option("--bundle") {
            handled = true
            setProjectVersion(cmd.arguments[0], log: &log)
        }

        if let cmd = cmd.option("--marketing") {
            handled = true
            setMarketingVersion(cmd.arguments[0], log: &log)
        }

        if handled == false {
            reportVersions(cmd.boolOption("--verbose"))
        } else {
            for target in log {
                for line in target {
                    print(line)
                }
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "version"
        command.synopsis = "AGV helpers."

        var initCmd = CommandOption()
        initCmd.longOption = "--init"
        initCmd.help = "Initialize versioning support."
        command.options.append(initCmd)

        var agvonlyCmd = CommandOption()
        agvonlyCmd.shortOption = "-a"
        agvonlyCmd.longOption = "--agvonly"
        agvonlyCmd.help = "Only set up AGV, not stamp phase or derived file."
        command.options.append(agvonlyCmd)

        var verboseCmd = CommandOption()
        verboseCmd.longOption = "--verbose"
        verboseCmd.help = "Verbose version output."
        command.options.append(verboseCmd)

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

        var dst = ParameterInfo()
        dst.hint = "target"
        dst.help = "Target(s) to act on"
        dst.completionCallback = { () -> [String] in
            if let proj = Helpers.findXcodeProject(FileManager.default.currentDirectoryPath, ignoreWorkspaces: true) {
                let targets = Helpers.findProjectTargets(proj)
                return targets.sorted()
            }
            return []
        }
        command.optionalParameters.append(dst)

        return command
    }

    // swiftlint:disable cyclomatic_complexity

    func bumpProjectVersion(log: inout [[String]]) {
        do {
            try locateFiles()

            var first: Bool = true
            var logIdx: Int = 0
            for target in targets {
                if targetFilter.count == 0 || targetFilter.contains(target.target.openStepComment) == true {
                    let firstLog: Bool = log[logIdx].count == 0
                    if first == false {
                        if firstLog {
                            log[logIdx].append("")
                        }
                    }
                    first = false
                    if firstLog {
                        log[logIdx].append(ANSIColor.brightBlue + "Target: " + target.target.openStepComment + ANSIColor.reset)
                    }

                    try determineVersionState(target: target)

                    switch target.versionSystemState {
                    case .unknown:
                        if firstLog {
                            log[logIdx].append("Version unknown")
                        }
                    case .genericPresent:
                        if firstLog {
                            log[logIdx].append("Generic Versioning")
                        }
                        target.projectVersion = String((Int(target.projectVersion) ?? 0) + 1)
                        log[logIdx].append("projectVersion = \(target.projectVersion)")
                        try writeGenericVersion(target: target)
                    case .appleGenericPresent:
                        if firstLog {
                            log[logIdx].append("Apple Generic Versioning")
                        }
                        target.projectVersion = String((Int(target.projectVersion) ?? 0) + 1)
                        log[logIdx].append("projectVersion = \(target.projectVersion)")
                        try writeAppleGenericVersion(target: target)
                    case .genericReady:
                        if firstLog {
                            log[logIdx].append("Generic Versioning not set up")
                        }
                    case .appleGenericReady:
                        if firstLog {
                            log[logIdx].append("Apple Generic Versioning not set up")
                        }
                    }
                    logIdx += 1
                }
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    // swiftlint:enable cyclomatic_complexity

    // swiftlint:disable cyclomatic_complexity

    func setProjectVersion(_ newVersion: String, log: inout [[String]]) {
        do {
            try locateFiles()

            var first: Bool = true
            var logIdx: Int = 0
            for target in targets {
                if targetFilter.count == 0 || targetFilter.contains(target.target.openStepComment) == true {
                    let firstLog: Bool = log[logIdx].count == 0
                    if first == false {
                        log[logIdx].append("")
                    }
                    first = false
                    if firstLog {
                        log[logIdx].append(ANSIColor.brightBlue + "Target: " + target.target.openStepComment + ANSIColor.reset)
                    }

                    try determineVersionState(target: target)

                    switch target.versionSystemState {
                    case .unknown:
                        if firstLog {
                            log[logIdx].append("Version unknown")
                        }
                    case .genericPresent:
                        if firstLog {
                            log[logIdx].append("Generic Versioning")
                        }
                        target.projectVersion = newVersion
                        log[logIdx].append("projectVersion = \(target.projectVersion)")
                        try writeGenericVersion(target: target)
                    case .appleGenericPresent:
                        if firstLog {
                            log[logIdx].append("Apple Generic Versioning")
                        }
                        target.projectVersion = newVersion
                        log[logIdx].append("projectVersion = \(target.projectVersion)")
                        try writeAppleGenericVersion(target: target)
                    case .genericReady:
                        if firstLog {
                            log[logIdx].append("Generic Versioning not set up")
                        }
                    case .appleGenericReady:
                        if firstLog {
                            log[logIdx].append("Apple Generic Versioning not set up")
                        }
                    }
                    logIdx += 1
                }
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    // swiftlint:enable cyclomatic_complexity

    // swiftlint:disable cyclomatic_complexity

    func setMarketingVersion(_ newVersion: String, log: inout [[String]]) {
        do {
            try locateFiles()

            var first: Bool = true
            var logIdx: Int = 0
            for target in targets {
                if targetFilter.count == 0 || targetFilter.contains(target.target.openStepComment) == true {
                    let firstLog: Bool = log[logIdx].count == 0
                    if first == false {
                        if firstLog {
                            log[logIdx].append("")
                        }
                    }
                    first = false
                    if firstLog {
                        log[logIdx].append(ANSIColor.brightBlue + "Target: " + target.target.openStepComment + ANSIColor.reset)
                    }

                    try determineVersionState(target: target)

                    switch target.versionSystemState {
                    case .unknown:
                        if firstLog {
                            log[logIdx].append("Version unknown")
                        }
                    case .genericPresent:
                        if firstLog {
                            log[logIdx].append("Generic Versioning")
                        }
                        target.marketingVersion = newVersion
                        log[logIdx].append("marketingVersion = \(target.marketingVersion)")
                        try writeGenericVersion(target: target)
                    case .appleGenericPresent:
                        if firstLog {
                            log[logIdx].append("Apple Generic Versioning")
                        }
                        target.marketingVersion = newVersion
                        log[logIdx].append("marketingVersion = \(target.marketingVersion)")
                        try writeAppleGenericVersion(target: target)
                    case .genericReady:
                        if firstLog {
                            log[logIdx].append("Generic Versioning not set up")
                        }
                    case .appleGenericReady:
                        if firstLog {
                            log[logIdx].append("Apple Generic Versioning not set up")
                        }
                    }
                    logIdx += 1
                }
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    // swiftlint:enable cyclomatic_complexity

    // swiftlint:disable cyclomatic_complexity

    func reportVersions(_ verbose: Bool) {
        do {
            try locateFiles()

            let derivedAndRunScript = { (target: NativeTargetWithConfigurations) in
                if target.derivedSourceState == .present {
                    if verbose == true {
                        print("Derived Source is set up.")
                    }
                } else {
                    print("Derived Source not set up.")
                }
                if target.runScriptState == .present {
                    if verbose == true {
                        print("Run script phase is set up.")
                    }
                } else {
                    print("Run script phase not set up.")
                }
            }

            var first: Bool = true
            for target in targets {
                if targetFilter.count == 0 || targetFilter.contains(target.target.openStepComment) == true {
                    if first == false {
                        print()
                    }
                    first = false
                    print(ANSIColor.brightBlue + "Target: " + target.target.openStepComment + ANSIColor.reset)

                    try determineVersionState(target: target)
                    try determineDerivedSourceState(target: target)
                    try determineRunScriptState(target: target)

                    switch target.versionSystemState {
                    case .unknown:
                        print("Version unknown")
                        derivedAndRunScript(target)
                    case .genericPresent:
                        if verbose == true {
                            print("Generic Versioning")
                        }
                        derivedAndRunScript(target)
                        print("Marketing Version: \(target.marketingVersion)")
                        print("Project Version:   \(target.projectVersion)")
                    case .appleGenericPresent:
                        if verbose == true {
                            print("Apple Generic Versioning")
                        }
                        derivedAndRunScript(target)
                        print("Marketing Version: \(target.marketingVersion)")
                        print("Project Version:   \(target.projectVersion)")
                    case .genericReady:
                        print("Generic Versioning not set up")
                        derivedAndRunScript(target)
                    case .appleGenericReady:
                        print("Apple Generic Versioning not set up")
                        derivedAndRunScript(target)
                    }
                }
            }
        } catch {
            print("Exception: \(error)")
        }
    }

    // swiftlint:enable cyclomatic_complexity

    func doInit(_ agvOnly: Bool = false) {
        do {
            try locateFiles()

            var first: Bool = true
            for target in targets {
                if targetFilter.count == 0 || targetFilter.contains(target.target.openStepComment) == true {
                    if first == false {
                        print()
                    }
                    first = false
                    print(ANSIColor.brightBlue + "Target: " + target.target.openStepComment + ANSIColor.reset)

                    try determineVersionState(target: target)
                    if agvOnly == false {
                        try determineDerivedSourceState(target: target)
                        try determineRunScriptState(target: target)
                    }

                    if target.versionSystemState == .unknown {
                        throw VersionCommandError.failed("Error: Could not determine version system state.")
                    }
                    if agvOnly == false {
                        if target.runScriptState == .unknown {
                            throw VersionCommandError.failed("Error: Could not determine run script state.")
                        }
                        if target.derivedSourceState == .unknown {
                            throw VersionCommandError.failed("Error: Could not determine derived source state.")
                        }
                    }

                    try actOnVersionState(target: target, agvOnly: agvOnly)
                    if agvOnly == false {
                        try actOnRunScriptState(target: target)
                        try actOnDerivedSourceState(target: target)
                    }
                }
            }
        } catch {
            print("Exception: \(error)")
        }

        print("Done.")
    }

    func locateFiles() throws {
        if xcodeProjectUrl != nil, project != nil, targets.count != 0, versionsStateFileUrl != nil {
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

        var targets: [NativeTargetWithConfigurations] = []

        let nativeTargets = rootObject.getTargets()?.compactMap { (target) -> PBXNativeTarget? in
            target as? PBXNativeTarget
        }

        for oneTarget in nativeTargets ?? [] {
            let holder = NativeTargetWithConfigurations(target: oneTarget)
            targets.append(holder)
        }

        targets = targets.filter { (item) -> Bool in
            if item.target.productType == "com.apple.product-type.bundle.unit-test" {
                return false
            }
            if item.configurations.count > 0 {
                return true
            }
            return false
        }

        if targets.count == 0 {
            throw VersionCommandError.failed("Error: Could not find any native targets with configurations")
        }

        targets.makeVersionsSwiftUnique()

        self.targets = targets

        versionsStateFileUrl = baseDirUrl.appendingPathComponent("versions.json")
    }

    func determineVersionState(target: NativeTargetWithConfigurations) throws {
        if target.versionSystemState != .unknown {
            // already run, move on
            return
        }

        guard let versionsStateFileUrl = self.versionsStateFileUrl else {
            throw VersionCommandError.failed("Error: versionsStateFileUrl not set")
        }

        guard let primaryConfiguration = primaryConfiguration(target: target) else {
            throw VersionCommandError.failed("Error: Could not read configurations")
        }

        if FileManager.default.fileExists(atPath: versionsStateFileUrl.path) == true {
            // generic system present
            target.versionSystemState = .genericPresent

            if let state = GenericVersionState.read(contentsOf: versionsStateFileUrl) {
                target.marketingVersion = state.marketingVersion
                target.projectVersion = state.projectVersion
            }
        } else if primaryConfiguration.buildSettings?.string(forKey: "VERSIONING_SYSTEM") == "apple-generic", let marketingVersion = primaryConfiguration.buildSettings?.string(forKey: "MARKETING_VERSION"), let projectVersion = primaryConfiguration.buildSettings?.string(forKey: "CURRENT_PROJECT_VERSION") {
            // apple generic system present
            target.versionSystemState = .appleGenericPresent
            target.marketingVersion = marketingVersion
            target.projectVersion = projectVersion
        } else if let plistPath = primaryConfiguration.buildSettings?.string(forKey: "INFOPLIST_FILE"), plistPath.count > 0 {
            // apple generic system ready
            target.versionSystemState = .appleGenericReady
            target.infoPlistFileUrl = xcodeProjectUrl?.deletingLastPathComponent().appendingPathComponent(plistPath)

            if let listUrl = target.infoPlistFileUrl {
                try determineVersionsFrom(plist: listUrl, target: target)
            }
        } else {
            // generic system ready
            target.versionSystemState = .genericReady
        }
    }

    func determineRunScriptState(target: NativeTargetWithConfigurations) throws {
        guard let buildPhases = target.target.getBuildPhases() else {
            throw VersionCommandError.failed("Error: Could not read build phases")
        }

        for phase in buildPhases {
            if let runPhase = phase as? PBXShellScriptBuildPhase {
                if let script = runPhase.shellScript {
                    if script.contains("pt stamp") == true {
                        target.runScriptState = .present
                        return
                    }
                }
            }
        }

        target.runScriptState = .ready
    }

    // swiftlint:disable cyclomatic_complexity

    func determineDerivedSourceState(target: NativeTargetWithConfigurations) throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            throw VersionCommandError.failed("Error: Could not read root object")
        }

        guard let mainGroup = rootObject.getMainGroup() else {
            throw VersionCommandError.failed("Error: Could not read main group")
        }

        target.derivedSourceState = .ready

        var versionsFileReference: PBXFileReference?

        if let childFiles = mainGroup.getChildren()?.compactMap({ (element) -> PBXFileReference? in
            element as? PBXFileReference
        }) {
            for childFile in childFiles {
                if childFile.path == target.versionsSwiftFilename, childFile.name == nil {
                    versionsFileReference = childFile
                    break
                }
            }
        }

        guard let theVersionsFileReference = versionsFileReference else {
            return
        }

        guard let buildPhases = target.target.getBuildPhases() else {
            return
        }

        for phase in buildPhases {
            if let sourcesPhase = phase as? PBXSourcesBuildPhase {
                if let files = sourcesPhase.getFiles() {
                    for file in files {
                        let fileRef = file.getFileRef()
                        if fileRef == theVersionsFileReference {
                            target.derivedSourceState = .present
                            return
                        }
                    }
                }
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity

    func actOnVersionState(target: NativeTargetWithConfigurations, agvOnly: Bool = false) throws {
        switch target.versionSystemState {
        case .unknown:
            throw VersionCommandError.failed("Error: Could not determine version system state.")
        case .genericPresent:
            print("Generic version system set up.")
        case .appleGenericPresent:
            print("Apple Generic version system set up.")
        case .genericReady:
            if agvOnly == false {
                print("Setting up Generic version system.")
                try setupGeneric(target: target)
            } else {
                print("Skipping set up of Generic version system.")
            }
        case .appleGenericReady:
            print("Setting up Apple Generic version system.")
            try setupAppleGeneric(target: target)
        }
    }

    func actOnRunScriptState(target: NativeTargetWithConfigurations) throws {
        switch target.runScriptState {
        case .unknown:
            throw VersionCommandError.failed("Error: Could not determine run script state.")
        case .present:
            print("Run script phase is set up.")
        case .ready:
            print("Setting up run script phase.")
            try setupRunScript(target: target)
        }
    }

    func actOnDerivedSourceState(target: NativeTargetWithConfigurations) throws {
        switch target.derivedSourceState {
        case .unknown:
            throw VersionCommandError.failed("Error: Could not determine derived source state.")
        case .present:
            print("Derived Source is set up.")
        case .ready:
            print("Setting up derived source.")
            try setupDerivedSource(target: target)
        }
    }

    func setupGeneric(target: NativeTargetWithConfigurations) throws {
        try writeGenericVersion(target: target)
    }

    func setupAppleGeneric(target: NativeTargetWithConfigurations) throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }
        guard let infoPlistFileUrl = target.infoPlistFileUrl else {
            throw VersionCommandError.failed("Error: infoPlistFileUrl not set")
        }

        for configuration in target.configurations {
            configuration.buildSettings?["VERSIONING_SYSTEM"] = "apple-generic" as AnyObject
            configuration.buildSettings?["MARKETING_VERSION"] = target.marketingVersion as AnyObject
            configuration.buildSettings?["CURRENT_PROJECT_VERSION"] = target.projectVersion as AnyObject
        }

        try project.write(to: project.path)

        let data = try Data(contentsOf: infoPlistFileUrl)
        var plist = try PropertyListSerialization.propertyList(from: data, options: [.mutableContainersAndLeaves], format: nil) as? [String: Any]
        plist?["CFBundleShortVersionString"] = "$(MARKETING_VERSION)"
        plist?["CFBundleVersion"] = "$(CURRENT_PROJECT_VERSION)"
        let outData = try PropertyListSerialization.data(fromPropertyList: plist as Any, format: .xml, options: 0)
        try outData.write(toFileURL: infoPlistFileUrl)
    }

    func setupRunScript(target: NativeTargetWithConfigurations) throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        let stampPhase = PBXShellScriptBuildPhase()
        stampPhase.buildActionMask = 2147483647
        stampPhase.outputPaths = ["$(DERIVED_FILE_DIR)/\(target.versionsSwiftFilename)"]
        stampPhase.name = "Stamp Version"
        stampPhase.shellPath = "/bin/sh"
        stampPhase.showEnvVarsInLog = false
        stampPhase.shellScript = """
        PATH=${PATH}:${HOME}/bin
        if which pt > /dev/null; then
        pt stamp '\(target.target.openStepComment)' "${DERIVED_FILE_DIR}/\(target.versionsSwiftFilename)"
        else
          echo "warning: pt not installed"
        fi
        """

        project.add(object: stampPhase, for: stampPhase.referenceKey)
        target.target.buildPhases?.insert(stampPhase.referenceKey, at: 0)

        try project.write(to: project.path)
    }

    // swiftlint:disable cyclomatic_complexity

    func setupDerivedSource(target: NativeTargetWithConfigurations) throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        guard let rootObject = project.object(withKey: project.rootObject) as? PBXProject else {
            throw VersionCommandError.failed("Error: Could not read root object")
        }

        guard let mainGroup = rootObject.getMainGroup() else {
            throw VersionCommandError.failed("Error: Could not read main group")
        }

        var versionsFileReference: PBXFileReference?

        if let childFiles = mainGroup.getChildren()?.compactMap({ (element) -> PBXFileReference? in
            element as? PBXFileReference
        }) {
            for childFile in childFiles {
                if childFile.path == target.versionsSwiftFilename, childFile.name == nil {
                    versionsFileReference = childFile
                    break
                }
            }
        }

        if versionsFileReference == nil {
            let fileReference = PBXFileReference()
            fileReference.fileEncoding = 4
            fileReference.lastKnownFileType = "sourcecode.swift"
            fileReference.path = target.versionsSwiftFilename
            fileReference.sourceTree = "DERIVED_FILE_DIR"
            project.add(object: fileReference, for: fileReference.referenceKey)
            mainGroup.children?.insert(fileReference.referenceKey, at: 0)
            versionsFileReference = fileReference
        }

        guard let theVersionsFileReference = versionsFileReference else {
            return
        }

        let sourcesPhase = target.target.getBuildPhases()?.filter { (phase) -> Bool in
            if phase is PBXSourcesBuildPhase {
                return true
            }
            return false
        }.first

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

    func writeGenericVersion(target: NativeTargetWithConfigurations) throws {
        guard let versionsStateFileUrl = self.versionsStateFileUrl else {
            throw VersionCommandError.failed("Error: versionsStateFileUrl not set")
        }

        let state = GenericVersionState(marketing: target.marketingVersion, project: target.projectVersion)
        state.write(to: versionsStateFileUrl)
    }

    func writeAppleGenericVersion(target: NativeTargetWithConfigurations) throws {
        guard let project = self.project else {
            throw VersionCommandError.failed("Error: project not set")
        }

        for configuration in target.configurations {
            configuration.buildSettings?["MARKETING_VERSION"] = target.marketingVersion as AnyObject
            configuration.buildSettings?["CURRENT_PROJECT_VERSION"] = target.projectVersion as AnyObject
        }

        try project.write(to: project.path)
    }

    func primaryConfiguration(target: NativeTargetWithConfigurations) -> XCBuildConfiguration? {
        let primaryConfigurationOptional = target.configurations.first { (config) -> Bool in
            config.name == "Release"
        } ?? target.configurations.first

        return primaryConfigurationOptional
    }

    func determineVersionsFrom(plist listUrl: URL, target: NativeTargetWithConfigurations) throws {
        let data = try Data(contentsOf: listUrl)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        if let info = plist as? [String: Any] {
            if let version = info["CFBundleShortVersionString"] as? String {
                target.marketingVersion = version
            }
            if let build = info["CFBundleVersion"] as? String {
                target.projectVersion = build
            }
        }
    }
}
