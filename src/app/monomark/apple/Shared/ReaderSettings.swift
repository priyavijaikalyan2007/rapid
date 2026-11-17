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
    @State private var about = false
    @State private var help = false
    @State private var palette = false
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
            Section("Reader colors")
            {
                Button("Customize Colors…")
                {
                    palette = true
                }
                Text("Separate light and dark palettes for headings, objects, and tables.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Reading layout")
            {
                Toggle("Automatically reload changed files", isOn: $session.preferences.autoReload)
                Toggle("Show source line numbers", isOn: $session.preferences.showLineNumbers)
                Text("The gutter marks each block's starting source line. Hover for its source range.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Preserve source line breaks", isOn: $session.preferences.preserveLineBreaks)
                Picker("View", selection: $session.preferences.layoutMode)
                {
                    Text("Pageless").tag("pageless")
                    Text("Pages").tag("pages")
                }
                Picker("Paper size", selection: $session.preferences.paperSize)
                {
                    Text("System default").tag("system")
                    Text("A4").tag("a4")
                    Text("US Letter").tag("letter")
                    Text("US Legal").tag("legal")
                }
                Text("Page counts are estimates. Large objects remain on an expanded sheet. Printed breaks can differ.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Typography")
            {
                Picker("Body font", selection: $session.preferences.fontFamily)
                {
                    Text("System Monospace").tag("ui-monospace")
                    ForEach(
                        FontChoices.make(installed: InstalledFonts.families, current: session.preferences.fontFamily),
                        id: \.self
                    )
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
            Section("History")
            {
                Button("Clear Viewing History", role: .destructive)
                {
                    session.clearHistory()
                }
                Text("Highlights, comments, and reading notes are kept separately.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Information")
            {
                Button("MonoMark Help")
                {
                    help = true
                }
                Button("About MonoMark")
                {
                    about = true
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $about)
        {
            ReaderAboutView()
        }
        .sheet(isPresented: $palette)
        {
            ReaderPaletteSettings(session: session)
        }
        .sheet(isPresented: $help)
        {
            ReaderHelpView()
        }
        .safeAreaInset(edge: .bottom)
        {
            VStack(spacing: 0)
            {
                Divider()
                ViewThatFits(in: .horizontal)
                {
                    HStack
                    { reset
                        defaults
                        Spacer()
                        done
                    }
                    VStack
                    { HStack
                    { reset
                        defaults
                    }
                        done
                    }
                }.padding(12)
            }.background(.regularMaterial)
        }
        #if os(macOS)
        .frame(minWidth: 680, idealWidth: 720, minHeight: 560)
        #else
        .frame(minWidth: 320, minHeight: 500)
        #endif
        .onChange(of: session.preferences)
        { _, _ in
            session.updatePreferences()
        }
    }

    private var reset: some View
    {
        Button("Reset Appearance")
        {
            session.preferences = ReaderPreferences()
        }
        .help("Reset this document's appearance")
    }

    private var defaults: some View
    {
        Button("Use as Defaults")
        {
            session.saveDefaults()
        }
        .help("Use these settings for documents without saved preferences")
    }

    private var done: some View
    {
        Button("Done")
        {
            session.showSettings = false
        }.keyboardShortcut(.defaultAction)
    }

    private func font(_ title: String, value: Binding<String>) -> some View
    {
        Picker(title, selection: value)
        {
            Text(title == "Code font" ? "System Monospace" : "Use body font").tag("")
            ForEach(FontChoices.make(installed: InstalledFonts.families, current: value.wrappedValue), id: \.self)
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
