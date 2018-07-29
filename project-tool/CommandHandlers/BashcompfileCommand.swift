//
//  BashcompfileCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

class BashcompfileCommand: Command {
    let format1 = """
_%@()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="$(${COMP_WORDS[0]} bashcomp ${COMP_WORDS[@]:1:$COMP_CWORD} "${cur}")"

    if [[ $opts = *"!files!"* ]]; then
        COMPREPLY=( $(compgen -df -- ${cur}) )
    else
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    fi

    return 0
}
"""

    let format2 = """
complete -o filenames -F _%@ %@
"""

    override func run(cmd: ParsedCommand) {
        print(String(format: format1, cmd.toolName))
        print(String(format: format2, cmd.toolName, cmd.toolName))
        for param in cmd.parameters {
            print(String(format: format2, cmd.toolName, param))
        }
    }
}
