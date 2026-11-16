// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 656aa5a4-8303-4d84-948d-f7b1c369a7f6
// Created: 2026
// COMPONENT: MonoMark platform app
// PURPOSE: Provide standard Mac menus, document opening, tabs, and a real-WebKit smoke harness.
// RELATES: ReaderSession.swift, ReaderView.swift
// FLOW: Platform event -> native document window -> reader session.

import AppKit
import SwiftUI
import WebKit

/// Native document actions remain in the normal menu and responder chain.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate
{
    var controllers: [ReaderWindowController] = []
    var informationWindows: [String: NSWindowController] = [:]
    var smokeStarted = false
    private var recentMenu = NSMenu(title: "Open Recent")
    var current: ReaderWindowController?
    {
        controllers.first
        {
            $0.window === NSApp.keyWindow
        } ?? controllers.last
    }

    func applicationDidFinishLaunching(_ notification: Notification)
    {
        buildMenu()
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--demo") || arguments.contains("--smoke-test")
        {
            let fixture = arguments.contains("--review-smoke") ? try? ReviewSmoke.createFixture() :
                arguments.contains("--artifact-smoke") ? try? SmokeFixture.create() : nil
            let file = fixture ?? FileManager.default.temporaryDirectory.appendingPathComponent("MonoMark-Demo.md")
            if fixture == nil, let data = Bundle.main.url(forResource: "Welcome", withExtension: "md")
            {
                do
                {
                    try Data(contentsOf: data).write(to: file)
                }
                catch
                {
                    present(error)
                }
            }
            createWindow(file: file, folder: fixture == nil ? nil : file.deletingLastPathComponent())
        }
        else if controllers.isEmpty
        {
            restoreTabs()
        }
        if let index = arguments.firstIndex(of: "--smoke-test"), arguments.indices.contains(index + 1)
        {
            if arguments.contains("--artifact-smoke") || arguments.contains("--review-smoke")
            {
                configureArtifactSmoke(output: arguments[index + 1], review: arguments.contains("--review-smoke"))
            }
            else
            {
                configureSmoke(output: arguments[index + 1])
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String])
    {
        for path in filenames
        {
            let file = URL(fileURLWithPath: path)
            if (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            {
                createWindow()
                selectFolder(file)
            }
            else
            {
                createWindow(file: file)
            }
        }
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
    {
        if !flag
        {
            createWindow()
        }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply
    {
        let sessions = controllers.map(\.session)
        Task
        {
            var ready = true
            for session in sessions
            {
                if !(await session.annotations.drain())
                {
                    ready = false
                }
            }
            sender.reply(toApplicationShouldTerminate: ready)
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification)
    {
        saveTabs()
        for controller in controllers
        {
            controller.session.close()
        }
    }

    func saveTabs()
    {
        let arguments = ProcessInfo.processInfo.arguments
        guard !arguments.contains("--demo"), !arguments.contains("--smoke-test")
        else
        {
            return
        }
        let records = controllers.compactMap
        {
            $0.session.state ?? $0.pendingRecord
        }
        if let data = try? JSONEncoder().encode(records)
        {
            UserDefaults.standard.set(data, forKey: "open-documents")
        }
    }

    private func restoreTabs()
    {
        guard let data = UserDefaults.standard.data(forKey: "open-documents"),
              let records = try? JSONDecoder().decode([ReadingState].self, from: data), !records.isEmpty
        else
        {
            createWindow()
            return
        }
        var first: NSWindow?
        for record in records.prefix(100)
        {
            let controller = ReaderWindowController(application: self)
            controller.pendingRecord = record
            controller.session.isSuspended = true
            controller.window?.title = record.title
            controllers.append(controller)
            if let first, let window = controller.window
            {
                first.addTabbedWindow(window, ordered: .above)
            }
            else
            {
                first = controller.window
            }
        }
        controllers.last?.showWindow(nil)
        controllers.last?.window?.makeKeyAndOrderFront(nil)
    }

    @discardableResult
    func createWindow(
        file: URL? = nil,
        folder: URL? = nil,
        tabbedWith parent: ReaderWindowController? = nil
    ) -> ReaderWindowController
    {
        let controller = ReaderWindowController(application: self)
        controllers.append(controller)
        if let parentWindow = parent?.window, let next = controller.window
        {
            parentWindow.addTabbedWindow(
                next,
                ordered: .above
            )
        }
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        if let file
        {
            controller.session.open(file, folder: folder)
        }
        return controller
    }

    @objc func openFile(_ sender: Any?)
    {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let file = panel.url
        else
        {
            return
        }
        if current?.session.url == nil
        {
            current?.session.open(file)
        }
        else
        {
            createWindow(file: file, tabbedWith: current)
        }
    }

    @objc func openFolder(_ sender: Any?)
    {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        guard panel.runModal() == .OK, let folder = panel.url
        else
        {
            return
        }
        selectFolder(folder)
    }

    private func selectFolder(_ folder: URL)
    {
        let controller = current ?? createWindow()
        controller.session.openWorkspace(folder)
    }

    @objc func newTab(_ sender: Any?)
    {
        createWindow(tabbedWith: current)
    }

    @objc func find(_ sender: Any?)
    {
        if searchingNotes
        {
            current?.session.annotations.noteSearchFocus = UUID()
        }
        else
        {
            current?.session.showFind = true
        }
    }

    @objc func nextMatch(_ sender: Any?)
    {
        if searchingNotes
        {
            current?.session.annotations.findNote(1)
        }
        else
        {
            current?.session.command(["type": "next", "direction": 1])
        }
    }

    @objc func previousMatch(_ sender: Any?)
    {
        if searchingNotes
        {
            current?.session.annotations.findNote(-1)
        }
        else
        {
            current?.session.command(["type": "next", "direction": -1])
        }
    }

    private var searchingNotes: Bool
    {
        guard let current, current.session.annotations.shown, current.session.annotations.inspectorTab == "Notes"
        else
        {
            return false
        }
        return (current.window?.firstResponder as? NSTextView)?.identifier?.rawValue == "reading-notes" ||
            current.session.annotations.notesSearchFocused
    }

    @objc func settings(_ sender: Any?)
    {
        current?.session.showSettings = true
    }

    @objc func toggleSidebar(_ sender: Any?)
    {
        current?.session.showSidebar.toggle()
    }

    @objc func fullScreen(_ sender: Any?)
    {
        current?.togglePresentation()
    }

    @objc func zoomIn(_ sender: Any?)
    {
        current?.session.command(["type": "zoom", "value": 0.1])
    }

    @objc func zoomOut(_ sender: Any?)
    {
        current?.session.command(["type": "zoom", "value": -0.1])
    }

    @objc func actualSize(_ sender: Any?)
    {
        current?.session.command(["type": "zoom", "value": 0])
    }

    @objc func largerText(_ sender: Any?)
    {
        changeText(1)
    }

    @objc func smallerText(_ sender: Any?)
    {
        changeText(-1)
    }

    @objc func printReader(_ sender: Any?)
    {
        current?.session.command(["type": "print"])
    }

    @objc func back(_ sender: Any?)
    {
        current?.session.go(-1)
    }

    @objc func forward(_ sender: Any?)
    {
        current?.session.go(1)
    }

    @objc func reload(_ sender: Any?)
    {
        current?.session.loadRenderer()
    }

    @objc func copyDocumentPath(_ sender: Any?)
    {
        current?.copyDocumentPath(sender)
    }

    @objc func openRecent(_ sender: NSMenuItem)
    {
        if let record = sender.representedObject as? ReadingState
        {
            current?.session.reopen(record)
        }
    }

    private func changeText(_ amount: Double)
    {
        guard let session = current?.session
        else
        {
            return
        }
        session.preferences.bodySize += amount
        session.updatePreferences()
    }

    func menuNeedsUpdate(_ menu: NSMenu)
    {
        guard menu === recentMenu, let session = current?.session
        else
        {
            return
        }
        session.refreshHistory()
        menu.removeAllItems()
        for record in session.history.prefix(20)
        {
            let item = NSMenuItem(title: record.title, action: #selector(openRecent(_:)), keyEquivalent: "")
            item.representedObject = record
            item.target = self
            menu.addItem(item)
        }
    }

    private func buildMenu()
    {
        let bar = NSMenu()
        NSApp.mainMenu = bar
        let app = submenu("MonoMark", on: bar)
        item("About MonoMark", #selector(showAbout(_:)), on: app)
        item("Settings…", #selector(settings(_:)), key: ",", on: app)
        app.addItem(.separator())
        item("Hide MonoMark", #selector(NSApplication.hide(_:)), key: "h", target: nil, on: app)
        item("Quit MonoMark", #selector(NSApplication.terminate(_:)), key: "q", target: nil, on: app)
        let file = submenu("File", on: bar)
        item("Open…", #selector(openFile(_:)), key: "o", on: file)
        item("Open Folder…", #selector(openFolder(_:)), on: file)
        let recent = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        recent.submenu = recentMenu
        recentMenu.delegate = self
        file.addItem(recent)
        item("New Tab", #selector(newTab(_:)), key: "t", on: file)
        item("Close", #selector(NSWindow.performClose(_:)), key: "w", target: nil, on: file)
        item("Copy Document Path", #selector(copyDocumentPath(_:)), on: file)
        item("Print…", #selector(printReader(_:)), key: "p", on: file)
        item("Export Notes and Annotations to This File", #selector(exportReadingData(_:)), on: file)
        item("Export a Copy…", #selector(exportReadingCopy(_:)), on: file)
        let edit = submenu("Edit", on: bar)
        item("Undo", Selector(("undo:")), key: "z", on: edit)
        item("Redo", Selector(("redo:")), key: "z", modifiers: [.command, .shift], on: edit)
        item("Cut", #selector(NSText.cut(_:)), key: "x", on: edit)
        item("Copy", #selector(NSText.copy(_:)), key: "c", target: nil, on: edit)
        item("Paste", #selector(NSText.paste(_:)), key: "v", on: edit)
        item("Select All", #selector(NSText.selectAll(_:)), key: "a", target: nil, on: edit)
        item("Find…", #selector(find(_:)), key: "f", on: edit)
        item("Find Next", #selector(nextMatch(_:)), key: "g", on: edit)
        item("Find Previous", #selector(previousMatch(_:)), key: "G", on: edit)
        let view = submenu("View", on: bar)
        item("Show or Hide Sidebar", #selector(toggleSidebar(_:)), on: view)
        item(
            "Enter or Exit Full Screen",
            #selector(fullScreen(_:)),
            key: "f",
            modifiers: [.command, .control],
            on: view
        )
        item("Pages", #selector(showPages(_:)), on: view)
        item("Pageless", #selector(showPageless(_:)), on: view)
        item("Zoom In", #selector(zoomIn(_:)), key: ">", modifiers: [.command, .shift], on: view)
        item("Zoom Out", #selector(zoomOut(_:)), key: "<", modifiers: [.command, .shift], on: view)
        item("Actual Size", #selector(actualSize(_:)), key: "0", on: view)
        item("Increase Text Size", #selector(largerText(_:)), key: "+", on: view)
        item("Decrease Text Size", #selector(smallerText(_:)), key: "-", on: view)
        item("Back", #selector(back(_:)), on: view)
        item("Forward", #selector(forward(_:)), on: view)
        item("Reload Document", #selector(reload(_:)), on: view)
        let windows = submenu("Window", on: bar)
        NSApp.windowsMenu = windows
        item("Minimize", #selector(NSWindow.performMiniaturize(_:)), key: "m", target: nil, on: windows)
        item("Show Next Tab", #selector(NSWindow.selectNextTab(_:)), target: nil, on: windows)
        item("Show Previous Tab", #selector(NSWindow.selectPreviousTab(_:)), target: nil, on: windows)
        item("Move Tab to New Window", #selector(NSWindow.moveTabToNewWindow(_:)), target: nil, on: windows)
        let help = submenu("Help", on: bar)
        item("MonoMark Help", #selector(showHelp(_:)), key: "?", on: help)
    }

    private func submenu(_ title: String, on parent: NSMenu) -> NSMenu
    {
        let entry = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        entry.submenu = menu
        parent.addItem(entry)
        return menu
    }

    private func item(
        _ title: String,
        _ action: Selector,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = .command,
        target: AnyObject? = nil,
        on menu: NSMenu
    )
    {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: key)
        entry.keyEquivalentModifierMask = modifiers
        entry.target = target ?? (responds(to: action) ? self : nil)
        menu.addItem(entry)
    }

    private func present(_ error: Error)
    {
        NSAlert(error: error).runModal()
    }
}
