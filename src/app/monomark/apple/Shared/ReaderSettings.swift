// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 25037606-3aba-4db2-a0d1-9b4ee63533e6
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Configure native reading preferences without editing source documents.
// RELATES: ReaderSession.swift
// FLOW: Native view -> validated session -> document surface.

import SwiftUI

/// Native controls edit bounded per-document typography and optional application defaults.
struct ReaderSettings: View
{
    @ObservedObject var session: ReaderSession
    @AppStorage("appearance-mode") private var appearance = "system"
    var body: some View
    {
        Form
        {
            Section("Appearance")
            {
                Picker("Mode", selection: $appearance)
                {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }
            Section("Typography")
            {
                Picker("Monospace font", selection: $session.preferences.fontFamily)
                {
                    ForEach(["ui-monospace", "Menlo", "Monaco", "Courier New", "SFMono-Regular"], id: \.self)
                    {
                        Text($0).tag($0)
                    }
                }
                font("Headings font", value: $session.preferences.headingFontFamily)
                font("Code font", value: $session.preferences.codeFontFamily)
                font("Table font", value: $session.preferences.tableFontFamily)
                font("Caption font", value: $session.preferences.captionFontFamily)
                size("Body", value: $session.preferences.bodySize)
                ForEach(0 ..< 6, id: \.self)
                { index in
                    size("Heading \(index + 1)", value: $session.preferences.headingSizes[index])
                }
                size("Code", value: $session.preferences.codeSize)
                size("Tables", value: $session.preferences.tableSize)
                size("Captions", value: $session.preferences.captionSize)
                Slider(value: $session.preferences.lineHeight, in: 1.1 ... 2.5)
                {
                    Text("Line spacing")
                }
                Slider(value: $session.preferences.pageWidth, in: 320 ... 1800)
                {
                    Text("Document width")
                }
            }
            Section("Tables")
            {
                Toggle("Band columns instead of rows", isOn: $session.preferences.columnBanding)
            }
            Section
            {
                Button("Use These Settings as Defaults")
                {
                    session.saveDefaults()
                }
                Button("Reset Document Appearance")
                {
                    session.preferences = ReaderPreferences()
                }
                Button("Clear Viewing History", role: .destructive)
                {
                    session.clearHistory()
                }
                Button("Done")
                {
                    session.showSettings = false
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 360, idealWidth: 440, minHeight: 500)
        .onChange(of: session.preferences)
        { _, _ in
            session.updatePreferences()
        }
    }

    private func font(_ title: String, value: Binding<String>) -> some View
    {
        Picker(title, selection: value)
        {
            Text("Use body font").tag("")
            ForEach(["Menlo", "Monaco", "Courier New", "SFMono-Regular"], id: \.self)
            {
                Text($0).tag($0)
            }
        }
    }

    private func size(_ title: String, value: Binding<Double>) -> some View
    {
        Stepper("\(title): \(Int(value.wrappedValue)) pt", value: value, in: 9 ... 80)
    }
}
