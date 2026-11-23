// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 03fa4ee0-77fb-41e5-ac84-9c6cc856e5b1
// COMPONENT: Native palette customization
// PURPOSE: Edit separate light and dark reader colors using named, contrast-checked swatches.
import SwiftUI

struct ReaderPaletteSettings: View
{
    @ObservedObject var session: ReaderSession
    @AppStorage("appearance-mode") private var appearance = "system"
    @Environment(\.dismiss) private var dismiss
    @State private var dark = false

    var body: some View
    {
        VStack(spacing: 0)
        {
            Form
            {
                Section("Reader colors")
                {
                    Picker("Edit palette", selection: $dark)
                    {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }.pickerStyle(.segmented)
                    HStack
                    {
                        Menu("Apply Preset")
                        {
                            preset("Default", name: "default")
                            preset("Neutral", name: "neutral")
                            preset("Ocean", name: "ocean")
                            preset("Forest", name: "forest")
                        }
                        Button(dark ? "Preview Dark" : "Preview Light")
                        {
                            appearance = dark ? "dark" : "light"
                        }
                    }
                    Text("Colors save automatically for this document and as defaults for new documents.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                roles("Headings", values: Array(PaletteRole.allCases.prefix(6)))
                roles("Captions, equations, and callouts", values: Array(PaletteRole.allCases[6 ... 10]))
                roles("Tables", values: Array(PaletteRole.allCases.suffix(5)))
                Section("Readability")
                {
                    Text("Text colors keep at least 4.5:1 contrast. Black or white replaces a color if needed.")
                    Text(
                        """
                        Callout colors apply to block quotes. Diagram author colors and code token colors stay \
                        separate.
                        """
                    )
                    Text("Select Band columns instead of rows in Settings to change table banding.")
                }.font(.caption).foregroundStyle(.secondary)
            }.formStyle(.grouped)
            Divider()
            HStack
            {
                Button(dark ? "Reset Dark Palette" : "Reset Light Palette")
                {
                    session.preferences.palette.reset(dark: dark)
                }
                Spacer()
                Button("Done")
                {
                    dismiss()
                }.keyboardShortcut(.defaultAction)
            }.padding(12)
        }
        #if os(macOS)
        .frame(minWidth: 600, idealWidth: 660, minHeight: 560)
        #else
        .frame(minWidth: 300)
        #endif
    }

    private func preset(_ title: String, name: String) -> some View
    {
        Button(title)
        {
            session.preferences.palette.preset(name, dark: dark)
        }
    }

    private func roles(_ title: String, values: [PaletteRole]) -> some View
    {
        Section(title)
        {
            ForEach(values, id: \.rawValue)
            { role in
                Picker(role.label, selection: Binding(
                    get: {
                        session.preferences.palette.choice(role: role, dark: dark)
                    },
                    set: {
                        session.preferences.palette.set(role: role, choice: $0, dark: dark)
                    }
                ))
                {
                    ForEach(PaletteSwatch.allCases, id: \.rawValue)
                    { swatch in
                        HStack
                        {
                            Circle().fill(color(swatch, surface: role.isSurface)).frame(width: 12, height: 12)
                            Text(swatch.label)
                        }.tag(swatch.rawValue)
                    }
                }
            }
        }
    }

    private func color(_ swatch: PaletteSwatch, surface: Bool) -> Color
    {
        let hex = swatch.hex(dark: dark, surface: surface)
        let rgb = UInt32(hex.dropFirst(), radix: 16) ?? 0
        return Color(
            .sRGB,
            red: Double((rgb >> 16) & 255) / 255,
            green: Double((rgb >> 8) & 255) / 255,
            blue: Double(rgb & 255) / 255
        )
    }
}
