#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: fdd04e41-cdfc-447c-8dd5-640f4ddeaf1b
# COMPONENT: Native profile evidence contracts
# PURPOSE: Keep helper totals, CPU units, and streamed native reports honest.
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from monomark_profile_metrics import cpu_seconds, parse_processes, select_processes, take_reports, resource_frame


class MonoMarkProfileTests(unittest.TestCase):
    def test_cpu_clock_formats_and_invalid_values(self):
        self.assertEqual(cpu_seconds("1-02:03:04.50"), 93784.5)
        self.assertEqual(cpu_seconds("12:03.25"), 723.25)
        with self.assertRaises(ValueError):
            cpu_seconds("1:99")
        with self.assertRaises(ValueError):
            cpu_seconds("0:nan")

    def test_combined_upper_bound_includes_existing_and_new_webkit_helpers(self):
        rows = parse_processes("10 0:01.00 100 /Apps/MonoMark\n20 0:02.00 200 /X/com.apple.WebKit.WebContent\n"
                               "30 0:03.00 300 /X/com.apple.WebKit.GPU\n40 0:04.00 400 /Apps/Other")
        self.assertEqual(set(select_processes(rows, 10)), {10, 20, 30})
        self.assertEqual(sum(row["rss_bytes"] for row in select_processes(rows, 10).values()), 600 * 1024)

    def test_negative_or_missing_process_fields_cannot_create_valid_measurements(self):
        with self.assertRaises(ValueError):
            parse_processes("10 0:01.00 -100 /Apps/MonoMark")
        with self.assertRaises(ValueError):
            parse_processes("10 0:01.00")

    def test_exited_app_counters_do_not_reset_the_measurement(self):
        rows = parse_processes("10 0:00.00 0 <defunct>\n20 0:02.00 200 /X/com.apple.WebKit.WebContent")
        self.assertEqual(set(select_processes(rows, 10)), {20})

    def test_app_counters_are_separate_from_all_webkit_upper_bound(self):
        rows = {10: {"cpu_seconds": 2, "usage": {"physicalBytes": 100}},
                20: {"cpu_seconds": 7, "usage": {"physicalBytes": 900}}}
        frame = resource_frame(rows, 10)
        self.assertEqual(frame, {"cpu": 9, "physicalBytes": 1000,
                                 "appCpu": 2, "appPhysicalBytes": 100})
        self.assertIsNone(resource_frame({}, 10)["appPhysicalBytes"])
        self.assertIsNone(resource_frame({10: {"cpu_seconds": 0, "usage": None}}, 10)["physicalBytes"])

    def test_streamed_reports_preserve_partial_json(self):
        reports, pending = take_reports('{"phase":"idle"}\n{"passed":')
        self.assertEqual(reports, [{"phase": "idle"}])
        reports, pending = take_reports(pending + 'true}\n')
        self.assertEqual((reports, pending), ([{"passed": True}], ""))
        with self.assertRaises(ValueError):
            take_reports('[1,2,3]\n')


if __name__ == "__main__":
    unittest.main()
