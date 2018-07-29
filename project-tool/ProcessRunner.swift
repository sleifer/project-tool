//
//  ProcessRunner.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

typealias ProcessRunnerHandler = (_ runner: ProcessRunner) -> Void

class ProcessRunner {

    let command: String
    let arguments: [String]
    var process: Process?
    var status: Int32 = -999
    var stdOut: String = ""
    var stdErr: String = ""

    init(_ cmd: String, args: [String]) {
        command = cmd
        arguments = args
    }

    func start(_ completion: ProcessRunnerHandler? = nil) {
        let proc = Process()
        process = proc
        proc.launchPath = command
        proc.arguments = arguments
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        let errPipe = Pipe()
        proc.standardError = errPipe

        proc.terminationHandler = { (process: Process) -> Void in
            self.status = process.terminationStatus

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: outData, encoding: .utf8) {
                self.stdOut.append(str)
            }

            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: errData, encoding: .utf8) {
                self.stdErr.append(str)
            }

            DispatchQueue.main.async {
                if let completion = completion {
                    completion(self)
                }
                endBackgroundTask()
                self.process = nil
            }
        }

        startBackgroundTask()
        proc.launch()
    }
}
