// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: f10f96c0-e019-4d43-ac73-4f9a18ad886c
// COMPONENT: Native searchable notes editor
// PURPOSE: Select and reveal search ranges while preserving native editing and undo.
import SwiftUI
#if os(macOS)
import AppKit

struct NativeNotesEditor: NSViewRepresentable
{
    @ObservedObject var controller: AnnotationController
    func makeCoordinator() -> NativeNotesCoordinator
    {
        NativeNotesCoordinator(controller)
    }

    func makeNSView(context: Context) -> NSScrollView
    {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        let editor = NSTextView(frame: NSRect(origin: .zero, size: scroll.contentSize))
        editor.isRichText = false
        editor.allowsUndo = true
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        editor.textColor = .textColor
        editor.backgroundColor = .textBackgroundColor
        editor.isVerticallyResizable = true
        editor.isHorizontallyResizable = false
        editor.autoresizingMask = [.width]
        editor.textContainer?.widthTracksTextView = true
        editor.textContainerInset = NSSize(width: 8, height: 8)
        editor.delegate = context.coordinator
        editor.identifier = NSUserInterfaceItemIdentifier("reading-notes")
        editor.setAccessibilityLabel("Reading notes")
        scroll.documentView = editor
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context)
    {
        guard let editor = scroll.documentView as? NSTextView
        else
        {
            return
        }
        if editor.string != controller.text
        {
            editor.string = controller.text
        }
        if context.coordinator.selectionGeneration != controller.noteSelectionGeneration
        {
            context.coordinator.selectionGeneration = controller.noteSelectionGeneration
            if let range = controller.noteSelection, NSMaxRange(range) <= (editor.string as NSString).length
            {
                editor.setSelectedRange(range)
                editor.scrollRangeToVisible(range)
            }
        }
    }
}
#else
import UIKit

struct NativeNotesEditor: UIViewRepresentable
{
    @ObservedObject var controller: AnnotationController
    func makeCoordinator() -> NativeNotesCoordinator
    {
        NativeNotesCoordinator(controller)
    }

    func makeUIView(context: Context) -> UITextView
    {
        let editor = UITextView()
        editor.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        editor.textColor = .label
        editor.backgroundColor = .systemBackground
        editor.autocorrectionType = .no
        editor.smartQuotesType = .no
        editor.smartDashesType = .no
        editor.delegate = context.coordinator
        editor.accessibilityLabel = "Reading notes"
        editor.accessibilityIdentifier = "reading-notes"
        return editor
    }

    func updateUIView(_ editor: UITextView, context: Context)
    {
        if editor.text != controller.text
        {
            editor.text = controller.text
        }
        if context.coordinator.selectionGeneration != controller.noteSelectionGeneration
        {
            context.coordinator.selectionGeneration = controller.noteSelectionGeneration
            if let range = controller.noteSelection, NSMaxRange(range) <= (editor.text as NSString).length
            {
                editor.selectedRange = range
                editor.scrollRangeToVisible(range)
            }
        }
    }
}
#endif
