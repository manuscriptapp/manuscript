//
//  FocusedValues+Find.swift
//  Manuscript
//
//  FocusedValue keys for Find & Replace menu commands
//

import SwiftUI

// MARK: - Find Actions

/// Actions that can be triggered from the Edit menu for Find functionality
struct FindActions {
    var showFind: () -> Void
    var showFindAndReplace: () -> Void
    var findNext: () -> Void
    var findPrevious: () -> Void
}

// MARK: - FocusedValue Key

struct FindActionsKey: FocusedValueKey {
    typealias Value = FindActions
}

extension FocusedValues {
    var findActions: FindActions? {
        get { self[FindActionsKey.self] }
        set { self[FindActionsKey.self] = newValue }
    }
}
