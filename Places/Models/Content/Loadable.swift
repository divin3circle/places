//
//  Loadable.swift
//  Places
//
//  Per-section fetch state. `.loaded([])` is an empty state, never a fallback.
//

import Foundation

nonisolated enum Loadable<T> {
    case idle
    case loading
    case loaded(T)
    case failed(String)
}
