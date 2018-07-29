//
//  Scanner-Extension.swift
//  project-tool
//
//  Created by Simeon Leifer on 9/16/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

extension Scanner {
    func scanCharacters(from set: CharacterSet) -> String? {
        var value: NSString?
        let scanned = self.scanCharacters(from: set, into: &value)
        if let value = value, scanned == true {
            let valueStr = value as String
            return valueStr
        }
        return nil
    }

    func scanUpToCharacters(from set: CharacterSet) -> String? {
        var value: NSString?
        let scanned = self.scanUpToCharacters(from: set, into: &value)
        if let value = value, scanned == true {
            let valueStr = value as String
            return valueStr
        }
        return nil
    }
}
