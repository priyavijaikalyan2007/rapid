// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e3bd74db-63fe-4484-ae25-202039510f12
// COMPONENT: Native product information
// PURPOSE: Show copyable version, build, copyright, license, and privacy details.
import SwiftUI

struct ReaderAboutView: View
{
    var showsDone = true
    @Environment(\.dismiss) private var dismiss
    private var information: ReaderInformation
    {
        var metadata = Bundle.main.infoDictionary ?? [:]
        if let url = Bundle.main.url(forResource: "build-info", withExtension: "json", subdirectory: "Renderer"),
           let data = try? Data(contentsOf: url),
           let build = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        {
            metadata["MonoMarkGitSHA"] = build["gitSHA"]
        }
        return ReaderInformation(metadata: metadata)
    }

    var body: some View
    {
        VStack(alignment: .leading, spacing: 16)
        {
            Label("MonoMark", systemImage: "doc.richtext").font(.largeTitle.bold())
            Text(information.versionDescription).foregroundStyle(.secondary).textSelection(.enabled)
            Text(information.copyright).textSelection(.enabled)
            Text("A local Markdown reader with highlights, comments, and reading notes.")
            Text("Privacy").font(.headline)
            Text(
                """
                Documents and reading data stay on this device. There are no accounts or analytics. External links \
                open in your browser.
                """
            )
            Text(
                """
                GNU General Public License, version 3 or later. Bundled libraries retain their own licenses and \
                notices.
                """
            )
            Link(
                "Report an Issue",
                destination: URL(string: "https://github.com/priyavijaikalyan2007/rapid/issues/new/choose")!
            )
            Link("View the GNU GPL", destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!)
            if showsDone
            {
                Button("Done")
                {
                    dismiss()
                }
            }
        }
        .padding(24)
        .frame(minWidth: 320, idealWidth: 480)
    }
}
