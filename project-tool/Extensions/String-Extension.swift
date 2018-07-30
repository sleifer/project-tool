//
//  String-Extension.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

extension String {
    var expandingTildeInPath: String {
        return NSString(string: self).expandingTildeInPath
    }

    var deletingLastPathComponent: String {
        return NSString(string: self).deletingLastPathComponent
    }

    var lastPathComponent: String {
        return NSString(string: self).lastPathComponent
    }

    var standardizingPath: String {
        return NSString(string: self).standardizingPath
    }

    var isAbsolutePath: Bool {
        return NSString(string: self).isAbsolutePath
    }

    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func appendingPathComponent(_ str: String) -> String {
        return NSString(string: self).appendingPathComponent(str)
    }

    subscript (idx: Int) -> Character {
        return self[index(startIndex, offsetBy: idx)]
    }

    subscript (idx: Int) -> String {
        return String(self[idx] as Character)
    }

    subscript(range: Range<Int>) -> String {
        let lower = self.index(self.startIndex, offsetBy: range.lowerBound)
        let upper = self.index(self.startIndex, offsetBy: range.upperBound)
        let substr = self[lower..<upper]
        return String(substr)
    }

    subscript(range: ClosedRange<Int>) -> String {
        let lower = self.index(self.startIndex, offsetBy: range.lowerBound)
        let upper = self.index(self.startIndex, offsetBy: range.upperBound)
        let substr = self[lower...upper]
        return String(substr)
    }

    func regex(_ pattern: String) -> [[String]] {
        var matches: [[String]] = []
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            for result in results {
                var submatches: [String] = []
                for idx in 0..<result.numberOfRanges {
                    let range = result.range(at: idx)
                    if range.location != NSNotFound {
                        let substr = self[range.location..<(range.length + range.location)]
                        submatches.append(substr)
                    }
                }
                matches.append(submatches)
            }
        } catch {
            print("invalid regex: \(error.localizedDescription)")
        }
        return matches
    }
}
