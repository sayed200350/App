import Foundation
import os.signpost

enum PerformanceMetrics {
    private static let log = OSLog(subsystem: "com.resilientme.app", category: "performance")

    static func mark(_ name: StaticString) {
        os_signpost(.event, log: log, name: name)
    }

    static func begin(_ name: StaticString) -> OSSignpostID {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        return id
    }

    static func end(_ name: StaticString, id: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }

    static func measure<R>(_ name: StaticString, _ block: () -> R) -> R {
        let id = begin(name)
        let result = block()
        end(name, id: id)
        return result
    }
}


