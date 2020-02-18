//
//  JSONReadWrite.swift
//  TripWire
//
//  Created by Simeon Leifer on 1/20/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Foundation

protocol JSONReadWrite where Self: Codable {
    associatedtype HostClass: Codable

    static func load(fromURL url: URL) -> HostClass?
    func save(toURL url: URL)
}

extension JSONReadWrite {
    static func load(fromURL url: URL) -> HostClass? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let object = try decoder.decode(HostClass.self, from: data)
            return object
        } catch {
            print("Error loading: \(error)")
        }
        return nil
    }

    func save(toURL url: URL) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Error saving: \(error)")
        }
    }
}
