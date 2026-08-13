//
//  Connectivity.swift
//  Places
//
//  Lightweight reachability so the UI can show an "offline" banner and callers
//  can skip network work they know will fail. Backed by NWPathMonitor.
//

import Foundation
import Network
import Observation

@Observable @MainActor
final class Connectivity {
    /// True when the device has a usable network path. Starts optimistic so the
    /// first frame doesn't flash the offline banner before the monitor reports.
    private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.places.connectivity")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor [weak self] in self?.isOnline = online }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
