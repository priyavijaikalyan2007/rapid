// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e795f68d-1ad5-4ffa-88f5-33245d83ae8d
// COMPONENT: Native notes editing delegate
// PURPOSE: Forward actual note edits and focus changes to the autosave controller.
import Foundation
#if os(macOS)
import AppKit

@MainActor
final class NativeNotesCoordinator: NSObject, NSTextViewDelegate
{
    let controller: AnnotationController
    var selectionGeneration: UUID?
    var documentToken: UUID?
    init(_ controller: AnnotationController)
    {
        self.controller = controller
    }

    func textDidChange(_ notification: Notification)
    {
        if let editor = notification.object as? NSTextView
        {
            controller.editNotes(editor.string)
        }
    }

    func textDidBeginEditing(_ notification: Notification)
    {
        controller.notesEditorFocused = true
    }

    func textDidEndEditing(_ notification: Notification)
    {
        controller.notesEditorFocused = false
    }
}
#else
import UIKit

@MainActor
final class NativeNotesCoordinator: NSObject, UITextViewDelegate
{
    let controller: AnnotationController
    var selectionGeneration: UUID?
    var documentToken: UUID?
    init(_ controller: AnnotationController)
    {
        self.controller = controller
    }

    func textViewDidChange(_ editor: UITextView)
    {
        controller.editNotes(editor.text)
    }

    func textViewDidBeginEditing(_ editor: UITextView)
    {
        controller.notesEditorFocused = true
    }

    func textViewDidEndEditing(_ editor: UITextView)
    {
        controller.notesEditorFocused = false
    }
}
#endif
