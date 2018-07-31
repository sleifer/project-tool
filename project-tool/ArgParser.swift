//
//  ArgParser.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

struct CommandOption {
    var shortOption: String?
    var longOption: String
    var argumentCount: Int
    var hasFileArguments: Bool
    var help: String

    init() {
        longOption = ""
        argumentCount = 0
        hasFileArguments = false
        help = ""
    }
}

struct ParsedOption {
    var longOption: String
    var arguments: [String]

    init() {
        longOption = ""
        arguments = []
    }
}

struct ParameterInfo {
    var hint: String
    var help: String

    init() {
        hint = ""
        help = ""
    }
}

struct CommandDefinition {
    var options: [CommandOption]
    var requiredParameters: [ParameterInfo]
    var optionalParameters: [ParameterInfo]
    var hasFileParameters: Bool
    var help: String
    var subcommands: [SubcommandDefinition]
    var defaultSubcommand: String?

    init() {
        options = []
        requiredParameters = []
        optionalParameters = []
        hasFileParameters = false
        help = ""
        subcommands = []
    }
}

struct SubcommandDefinition {
    var options: [CommandOption]
    var requiredParameters: [ParameterInfo]
    var optionalParameters: [ParameterInfo]
    var hasFileParameters: Bool
    var name: String
    var synopsis: String
    var help: String
    var hidden: Bool
    var suppressesOptions: Bool
    var warnOnMissingSpec: Bool

    init() {
        options = []
        requiredParameters = []
        optionalParameters = []
        hasFileParameters = false
        name = ""
        synopsis = ""
        help = ""
        hidden = false
        suppressesOptions = false
        warnOnMissingSpec = true
    }
}

struct ParsedCommand {
    var toolName: String
    var subcommand: String?
    var options: [ParsedOption]
    var parameters: [String]
    var warnOnMissingSpec: Bool

    init() {
        toolName = ""
        options = []
        parameters = []
        warnOnMissingSpec = true
    }

    func option(_ name: String) -> ParsedOption? {
        var option: ParsedOption?

        option = self.options.first(where: { (option: ParsedOption) -> Bool in
            if option.longOption == name {
                return true
            }
            return false
        })

        return option
    }
}

enum ArgParserError: Error {
    case invalidArguments
}

class ArgParser {
    let definition: CommandDefinition

    var args: [String] = []
    var parsed: ParsedCommand = ParsedCommand()
    var subcommand: SubcommandDefinition?
    var helpPrinted = false

    init(definition inDefinition: CommandDefinition) {
        definition = inDefinition
    }

    func parse(_ inArgs: [String]) throws -> ParsedCommand {
        args = inArgs.splittingShortArgs()

        if args.count == 1 {
            printHelp()
            helpPrinted = true
        }

        var availableOptions = optionMap(definition.options)
        let availableSubcommands = subcommandMap(definition.subcommands)
        subcommand = nil

        if let defaultSubcommandName = definition.defaultSubcommand, let defaultSubcommand = availableSubcommands[defaultSubcommandName] {
            parsed.subcommand = defaultSubcommandName
            subcommand = defaultSubcommand
            let subOptions = optionMap(defaultSubcommand.options)
            availableOptions = availableOptions.merging(subOptions, uniquingKeysWith: { (first, _) -> CommandOption in
                return first
            })
        }
        var subcommandSet: Bool = false

        parsed.toolName = args[0]

        let sargs = Array(args.dropFirst())
        let cnt = sargs.count
        var idx = 0
        while idx < cnt {
            let arg = sargs[idx]
            if let value = availableOptions[arg], subcommand == nil || (subcommand != nil && subcommand?.suppressesOptions == false) {
                var option = ParsedOption()
                option.longOption = value.longOption
                idx += 1
                if value.argumentCount > 0 {
                    if cnt - idx <= value.argumentCount {
                        for _ in 0..<value.argumentCount {
                            option.arguments.append(sargs[idx])
                            idx += 1
                        }
                    } else {
                        throw ArgParserError.invalidArguments
                    }
                }
                parsed.options.append(option)
            } else if let value = availableSubcommands[arg], subcommandSet == false {
                parsed.subcommand = value.name
                subcommand = value
                subcommandSet = true

                if value.warnOnMissingSpec == false {
                    parsed.warnOnMissingSpec = false
                }

                availableOptions = optionMap(definition.options)
                let subOptions = optionMap(value.options)
                availableOptions = availableOptions.merging(subOptions, uniquingKeysWith: { (first, _) -> CommandOption in
                    return first
                })
                idx += 1
            } else {
                parsed.parameters.append(arg)
                idx += 1
            }
        }

        return parsed
    }

    func optionMap(_ optionArray: [CommandOption]) -> [String: CommandOption] {
        var map: [String: CommandOption] = [:]

        for option in optionArray {
            if let short = option.shortOption {
                map[short] = option
            }
            map[option.longOption] = option
        }

        return map
    }

    func subcommandMap(_ subcommandArray: [SubcommandDefinition]) -> [String: SubcommandDefinition] {
        var map: [String: SubcommandDefinition] = [:]

        for option in subcommandArray {
            map[option.name] = option
        }

        return map
    }

    fileprivate func printGlobalHelp() {
        if definition.options.count > 0 {
            print()
            print("Options:")
            var optionStrings: [[String]] = []
            for option in definition.options {
                var argCount = ""
                if option.argumentCount > 0 {
                    argCount = "<\(option.argumentCount) args>"
                }
                if let shortOption = option.shortOption {
                    optionStrings.append(["\(shortOption), \(option.longOption)", argCount, option.help])
                } else {
                    optionStrings.append(["\(option.longOption)", argCount, option.help])
                }
            }
            let maxOptionLength = optionStrings.map({ (item: [String]) -> String in
                return item[0]
            }).maxCount()
            let maxArgCountLength = optionStrings.map({ (item: [String]) -> String in
                return item[1]
            }).maxCount()
            let pad = String(repeating: " ", count: max(maxOptionLength, maxArgCountLength))
            for optionInfo in optionStrings {
                print("\(optionInfo[0].padding(toLength: maxOptionLength, withPad: pad, startingAt: 0)) \(optionInfo[1].padding(toLength: maxArgCountLength, withPad: pad, startingAt: 0)) \(optionInfo[2])")
            }
        }
        if definition.requiredParameters.count > 0 {
            print()
            print("Required Parameters:")
            let maxHintLength = definition.requiredParameters.map({ (item) -> String in
                return item.hint
            }).maxCount()
            let pad = String(repeating: " ", count: maxHintLength)
            for param in definition.requiredParameters {
                print("\(param.hint.padding(toLength: maxHintLength, withPad: pad, startingAt: 0))    \(param.help)")
            }
        }
        if definition.optionalParameters.count > 0 {
            print()
            print("Optional Parameters:")
            let maxHintLength = definition.optionalParameters.map({ (item) -> String in
                return item.hint
            }).maxCount()
            let pad = String(repeating: " ", count: maxHintLength)
            for param in definition.optionalParameters {
                print("\(param.hint.padding(toLength: maxHintLength, withPad: pad, startingAt: 0))    \(param.help)")
            }
        }
    }

    fileprivate func printSubcommandHelp(_ sub: SubcommandDefinition) {
        if sub.options.count > 0 {
            print()
            print("Options:")
            var optionStrings: [[String]] = []
            for option in sub.options {
                var argCount = ""
                if option.argumentCount > 0 {
                    argCount = "<\(option.argumentCount) args>"
                }
                if let shortOption = option.shortOption {
                    optionStrings.append(["\(shortOption), \(option.longOption)", argCount, option.help])
                } else {
                    optionStrings.append(["\(option.longOption)", argCount, option.help])
                }
            }
            let maxOptionLength = optionStrings.map({ (item: [String]) -> String in
                return item[0]
            }).maxCount()
            let maxArgCountLength = optionStrings.map({ (item: [String]) -> String in
                return item[1]
            }).maxCount()
            let pad = String(repeating: " ", count: max(maxOptionLength, maxArgCountLength))
            for optionInfo in optionStrings {
                print("\(optionInfo[0].padding(toLength: maxOptionLength, withPad: pad, startingAt: 0)) \(optionInfo[1].padding(toLength: maxArgCountLength, withPad: pad, startingAt: 0)) \(optionInfo[2])")
            }
        }
        if sub.requiredParameters.count > 0 {
            print()
            print("Required Parameters:")
            let maxHintLength = sub.requiredParameters.map({ (item) -> String in
                return item.hint
            }).maxCount()
            let pad = String(repeating: " ", count: maxHintLength)
            for param in sub.requiredParameters {
                print("\(param.hint.padding(toLength: maxHintLength, withPad: pad, startingAt: 0))    \(param.help)")
            }
        }
        if sub.optionalParameters.count > 0 {
            print()
            print("Optional Parameters:")
            let maxHintLength = sub.optionalParameters.map({ (item) -> String in
                return item.hint
            }).maxCount()
            let pad = String(repeating: " ", count: maxHintLength)
            for param in sub.optionalParameters {
                print("\(param.hint.padding(toLength: maxHintLength, withPad: pad, startingAt: 0))    \(param.help)")
            }
        }
    }

    func printHelp() {
        let toolname = args[0].lastPathComponent
        if let sub = subcommand {
            print("Usage: \(toolname) [OPTIONS] \(sub.name) [ARGS]...")
            print()
            print("\(sub.synopsis)")
            if sub.help.count > 0 {
                print()
                print("\(sub.help)")
            }
        } else {
            print("Usage: \(toolname) [OPTIONS] COMMAND [ARGS]...")
            print()
            print("\(definition.help)")
        }
        printGlobalHelp()
        if let sub = subcommand {
            printSubcommandHelp(sub)
        } else {
            let subs = definition.subcommands.filter { (item) -> Bool in
                return item.hidden == false
            }
            if subs.count > 0 {
                print()
                print("Commands:")
                let maxNameLength = subs.map({ (item: SubcommandDefinition) -> String in
                    return item.name
                }).maxCount()
                let pad = String(repeating: " ", count: maxNameLength)
                for sub in subs {
                    print("\(sub.name.padding(toLength: maxNameLength, withPad: pad, startingAt: 0))    \(sub.synopsis)")
                }
            }
        }
    }
}

extension Collection where Element == String {
    func maxCount() -> Int {
        var maxCount = 0
        for item in self {
            let count = item.count
            if count > maxCount {
                maxCount = count
            }
        }
        return maxCount
    }

    func splittingShortArgs() -> [String] {
        return self.map { (item) -> [String] in
            var items: [String] = []
            if item.hasPrefix("-") == true && item.hasPrefix("--") == false {
                for char in item {
                    if char != "-" {
                        items.append("-\(char)")
                    }
                }
            } else {
                return [item]
            }
            return items
            }.reduce([String](), +)
    }
}
