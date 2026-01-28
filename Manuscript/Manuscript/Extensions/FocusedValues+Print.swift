//
//  FocusedValues+Print.swift
//  Manuscript
//
//  FocusedValue keys for Print menu commands
//

import SwiftUI

// MARK: - FocusedValue Key for Print Binding

struct PrintSheetBindingKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var printSheetBinding: Binding<Bool>? {
        get { self[PrintSheetBindingKey.self] }
        set { self[PrintSheetBindingKey.self] = newValue }
    }
}
