//
//  Haptics.swift
//  WomensHealthApp
//
//  Usage (match the rest of the app):
//  - Buttons / taps / list row selection → Haptics.selection()
//  - Pull-to-refresh (.refreshable) → Haptics.refresh() at start of closure
//  - Tab bar / segment changes → Haptics.selection()
//  - Success (e.g. save completed) → Haptics.success()
//

import UIKit

enum Haptics {
    /// Light tap for buttons and selections
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    /// Light impact for secondary actions
    static func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Medium impact for pull-to-refresh
    static func refresh() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Success notification (e.g. save completed)
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
