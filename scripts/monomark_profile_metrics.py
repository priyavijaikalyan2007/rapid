#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: 7026d248-9141-440d-95fb-dd5db0f643cd
# COMPONENT: Native profiling evidence
# PURPOSE: Parse OS process counters and preserve complete JSON report boundaries.
import json
import math
from typing import TypedDict


class ProcessSample(TypedDict):
    pid: int
    cpu_seconds: float
    rss_bytes: int
    command: str


def cpu_seconds(value: str) -> float:
    """Convert ps cumulative CPU clocks, including days, to seconds."""
    days = 0
    if "-" in value:
        day, value = value.split("-", 1)
        days = int(day)
    parts = value.split(":")
    if len(parts) not in (2, 3):
        raise ValueError("Invalid process CPU clock")
    seconds = float(parts[-1])
    minutes = int(parts[-2])
    hours = int(parts[0]) if len(parts) == 3 else 0
    if not math.isfinite(seconds) or seconds < 0 or seconds >= 60 or minutes < 0 or hours < 0 or days < 0:
        raise ValueError("Invalid process CPU clock")
    return days * 86400 + hours * 3600 + minutes * 60 + seconds


def parse_processes(text: str) -> dict[int, ProcessSample]:
    """Read headerless ps output without retaining unrelated environment or command arguments."""
    result = {}
    for line in text.splitlines():
        if not line.strip():
            continue
        pid_text, clock, rss_text, command = line.split(None, 3)
        pid, rss = int(pid_text), int(rss_text)
        if pid < 0 or rss < 0:
            raise ValueError("Negative process counter")
        result[pid] = {"pid": pid, "cpu_seconds": cpu_seconds(clock),
                       "rss_bytes": rss * 1024, "command": command}
    return result


def select_processes(rows: dict[int, ProcessSample], app_pid: int) -> dict[int, ProcessSample]:
    """Include all WebKit helpers as an explicit upper bound, including helpers from other applications."""
    return {pid: row for pid, row in rows.items()
            if row["command"] != "<defunct>" and
            (pid == app_pid or row["command"].rsplit("/", 1)[-1].startswith("com.apple.WebKit."))}


def take_reports(buffer: str) -> tuple[list[dict], str]:
    """Accept multiple JSON objects and retain an incomplete final object until the next read."""
    reports = []
    decoder = json.JSONDecoder()
    buffer = buffer.lstrip()
    while buffer:
        if buffer[0] not in "{[":
            raise ValueError("Unexpected native test output")
        try:
            report, end = decoder.raw_decode(buffer)
        except json.JSONDecodeError:
            return reports, buffer
        if not isinstance(report, dict):
            raise ValueError("Native reports must be JSON objects")
        reports.append(report)
        buffer = buffer[end:].lstrip()
    return reports, ""


def resource_frame(rows: dict, app_pid: int) -> dict:
    """Keep app-only counters distinct from the all-WebKit upper bound."""
    physical = [row["usage"]["physicalBytes"] if row.get("usage") else None for row in rows.values()]
    app = rows.get(app_pid)
    return {"cpu": sum(row["cpu_seconds"] for row in rows.values()),
            "physicalBytes": sum(physical) if physical and None not in physical else None,
            "appCpu": app["cpu_seconds"] if app else None,
            "appPhysicalBytes": app["usage"]["physicalBytes"] if app and app.get("usage") else None}
