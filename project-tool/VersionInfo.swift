//
//  VersionInfo.swift
//  project-tool
//
//  Created by Simeon Leifer on 11/3/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Foundation

enum VersionField: Int {
    case major
    case minor
    case patch
    case build
}

struct VersionInfo {
    var fields: [Int]
    let depth: VersionField

    var string: String {
        fields.map { (value) -> String in
            "\(value)"
        }.joined(separator: ".")
    }

    init(_ version: String, depth: VersionField = .patch) {
        var parts = version.components(separatedBy: ".").compactMap { (partStr) -> Int? in
            Int(partStr)
        }
        parts.append(contentsOf: [0, 0, 0, 0])

        self.fields = Array(parts[0 ... depth.rawValue])
        self.depth = depth
    }

    mutating func bump(_ field: VersionField) {
        fields[field.rawValue] += 1
        if field.rawValue + 1 <= depth.rawValue {
            for idx in field.rawValue + 1 ... depth.rawValue {
                fields[idx] = 0
            }
        }
    }

    func field(_ field: VersionField) -> Int {
        return fields[field.rawValue]
    }
}
