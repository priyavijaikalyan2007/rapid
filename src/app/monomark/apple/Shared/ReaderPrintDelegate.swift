// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 1c5d6d26-50c0-4fea-a738-c4e77dfc57fd
// COMPONENT: Mobile paper selection
// PURPOSE: Choose the printer's nearest supported paper without changing global preferences.
#if os(iOS)
import UIKit

@MainActor final class ReaderPrintDelegate: NSObject, UIPrintInteractionControllerDelegate
{
    let paper: PaperLayout
    init(paper: PaperLayout)
    {
        self.paper = paper
    }

    func printInteractionController(
        _ printInteractionController: UIPrintInteractionController,
        choosePaper paperList: [UIPrintPaper]
    ) -> UIPrintPaper
    {
        UIPrintPaper.bestPaper(
            forPageSize: CGSize(width: paper.widthPoints, height: paper.heightPoints),
            withPapersFrom: paperList
        )
    }
}
#endif
