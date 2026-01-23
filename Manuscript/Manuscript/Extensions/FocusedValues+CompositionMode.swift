//
//  FocusedValues+CompositionMode.swift
//  Manuscript
//
//  FocusedValue keys for Composition Mode menu commands
//

import SwiftUI

// MARK: - FocusedValue Key for Composition Mode Binding

struct CompositionModeBindingKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var compositionModeBinding: Binding<Bool>? {
        get { self[CompositionModeBindingKey.self] }
        set { self[CompositionModeBindingKey.self] = newValue }
    }
}
