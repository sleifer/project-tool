//
//  DocumentationCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 4/23/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore
import Yaml

class DocumentationCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var outputDir: String?
        do {
            let yamlContent = try String(contentsOfFile: ".jazzy.yaml")
            let yaml = try Yaml.load(yamlContent)
            outputDir = yaml["output"].string
        } catch {
        }

        if cmd.option("--skip") == nil {
            ProcessRunner.runCommand("jazzy", echoOutput: true)

            ProcessRunner.runCommand("rm -r build")
        }

        if cmd.option("--html") != nil {
            if let value = outputDir {
                let htmlPath = value.appendingPathComponent("index.html")
                if FileManager.default.fileExists(atPath: htmlPath) == false {
                    print("Could not locate index.html.")
                } else {
                    ProcessRunner.runCommand("open '\(htmlPath)'")
                }
            } else {
                print("Could not locate output directory.")
            }
        }

        if cmd.option("--docset") != nil {
            if let value = outputDir {
                let docsetDir = value.appendingPathComponent("docsets")
                if FileManager.default.fileExists(atPath: docsetDir) == false {
                    print("Could not locate docset dir.")
                } else {
                    do {
                        let files = try FileManager.default.contentsOfDirectory(atPath: docsetDir)
                        for file in files {
                            if file.hasSuffix(".docset") == true {
                                let path = docsetDir.appendingPathComponent(file)
                                ProcessRunner.runCommand("open '\(path)'")
                            }
                        }
                    } catch {
                        print("Error getting contents of docset dir: \(error)")
                    }
                }
            } else {
                print("Could not locate output directory.")
            }
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "docs"
        command.synopsis = "Use jazzy to generate documentation for project."

        var skipOption = CommandOption()
        skipOption.shortOption = "-s"
        skipOption.longOption = "--skip"
        skipOption.help = "Skip building documentation."
        command.options.append(skipOption)

        var htmlOption = CommandOption()
        htmlOption.shortOption = "-t"
        htmlOption.longOption = "--html"
        htmlOption.help = "Open html documentation after generation."
        command.options.append(htmlOption)

        var docsetOption = CommandOption()
        docsetOption.shortOption = "-d"
        docsetOption.longOption = "--docset"
        docsetOption.help = "Open docset documentation after generation."
        command.options.append(docsetOption)

        return command
    }
}
