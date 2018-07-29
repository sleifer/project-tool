//
//  Array-Extension.swift
//  project-tool
//
//  Created by Simeon Leifer on 1/16/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

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
