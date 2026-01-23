//
//  FocusedValues+Export.swift
//  Manuscript
//
//  FocusedValue keys for Export menu commands
//

import SwiftUI

// MARK: - FocusedValue Key for Export Binding

struct ExportSheetBindingKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var exportSheetBinding: Binding<Bool>? {
        get { self[ExportSheetBindingKey.self] }
        set { self[ExportSheetBindingKey.self] = newValue }
    }
}
