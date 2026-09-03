//
//  NSMetadataQuery+SY.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

extension NSMetadataQuery {
    static func paths(predicateFormat: String, arguments: [Any] = [], baseURL: URL) -> [URL] {
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        query.searchScopes = [baseURL.standardizedFileURL.path(percentEncoded: false)]

        var finished = false
        let observer = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query,
            queue: nil
        ) { _ in
            finished = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        query.start()
        while !finished {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }
        query.stop()

        return query.results.compactMap { result in
            (result as? NSMetadataItem)?.value(forAttribute: NSMetadataItemPathKey) as? String
        }.map {
            URL(filePath: $0)
        }
    }
}
