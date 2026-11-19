// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 19bf2c70-c1e3-4b2d-ae58-262c43bd847d
// COMPONENT: MonoMark product information
// PURPOSE: Present bundle version details and local reading-data help.
import Foundation

struct ReaderInformation: Sendable
{
    let versionDescription: String
    let copyright: String

    init(metadata: [String: Any])
    {
        let version = metadata["CFBundleShortVersionString"] as? String ?? "development"
        let build = metadata["CFBundleVersion"] as? String ?? "development"
        let revision = metadata["MonoMarkGitSHA"] as? String ?? "development"
        versionDescription = "Version \(version) (build \(build), \(revision))"
        copyright = metadata["NSHumanReadableCopyright"] as? String ?? "© 2026 Outcrop Inc."
    }

    static let help: [ReaderHelpTopic] = [
        ReaderHelpTopic(
            title: "Open files and folders",
            detail:
            """
            Open a Markdown file to read it. Open its folder to browse related documents and grant access to local \
            images and links. Files marks the current document. The title bar shows its path. Document Location opens a selectable path and Copy Path action. Each folder is a workspace. The menu above Files switches recent workspaces and \
            resumes the last available document. Click a file to reuse the current tab. On Mac, Command-click opens \
            a new tab. The context menu also offers Open in New Tab. Other tabs stay open. Forget This Workspace keeps files and notes.
            """
        ),
        ReaderHelpTopic(
            title: "Highlights and comments",
            detail:
            """
            Select document text, open Notes and Annotations, choose a color, and select Highlight. Add a comment \
            in the expanded panel. Click its quotation or a document highlight to jump to the marked line. New \
            panels start expanded. Use the toolbar to expand or collapse all panels.
            """
        ),
        ReaderHelpTopic(
            title: "Search annotations and notes",
            detail:
            """
            Search annotations by quotation or comment. The Notes tab provides a separate text search and \
            previous/next matches. Notes can be Markdown or plain text. On Mac, Command-F and Command-G use notes \
            when the notes editor or its search field has focus.
            """
        ),
        ReaderHelpTopic(
            title: "Where reading data is stored",
            detail:
            """
            Highlights, comments, notes, reading positions, and settings stay on this device. On Mac, the \
            Application Support folder contains a MonoMark folder. Reading data is separate from Markdown files. \
            Clearing viewing history does not delete notes or highlights. Quit the Mac app before copying that \
            folder for a backup. On iPhone and iPad, the data stays in the app container.
            """
        ),
        ReaderHelpTopic(
            title: "Export notes and annotations",
            detail:
            """
            Notes save automatically inside the app. On Mac, File > Export Notes and Annotations to This File \
            writes a marked, auto-generated Markdown section. Each export replaces that section and preserves the \
            surrounding source. Highlighted text appears as a labeled quotation. Comments appear separately. Export a Copy keeps the original unchanged and is also available on mobile. Save \
            and Command-S do not write reading notes into the original file.
            """
        ),
        ReaderHelpTopic(
            title: "Changes and recovery",
            detail:
            """
            Another editor can change the source. Reload to read the latest content. A quotation that cannot be \
            attached stays in the inspector. If another window changes your notes, your visible draft remains \
            available. Copy the draft, use the explicit retry action, or reload saved notes. Normal document and \
            app closure waits for pending note edits.
            """
        ),
        ReaderHelpTopic(
            title: "Appearance and printing",
            detail:
            """
            Settings offers System, Light, and Dark appearance, installed font families, and sizes for document \
            elements. Customize Colors provides separate Light and Dark palettes, presets, and reset controls. \
            Text colors keep at least 4.5:1 contrast. Diagram colors remain separate. Settings save automatically, \
            including when no document is open. New documents inherit those settings. Existing documents retain \
            their saved reader settings. Use File > Print on Mac or \
            Document Actions > Print on mobile. Printing supports up to 5,000 blocks, 16 MiB of rendered HTML, and 100,000 rendered elements. \
            Each block must fit the 1 MiB rendered-object limit. Larger jobs report the limit before printing. Pages shows separate paper boxes. Pageless uses continuous \
            scrolling. Choose paper size in Settings. Counts are estimates \
            and change with width and typography. Optional source line numbers mark block starts, with ranges on hover. \
            Preserve source line breaks keeps single source newlines visible. Both options are in Reading layout. \
            Subsection numbering follows the source author. Large objects stay on expanded sheets. Printed breaks can differ.
            """
        )
    ]
}
