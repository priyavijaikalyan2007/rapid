#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: 91472cfe-e2df-42f7-8cfd-9937e18ba80c
# COMPONENT: MonoMark native performance checks
# PURPOSE: Run synthetic viewer workloads and measure the app plus a conservative all-WebKit resource bound.
import argparse
import codecs
import hashlib
import json
import os
from pathlib import Path
import platform
import selectors
import struct
import subprocess
import sys
import tempfile
import time
import zlib

from monomark_profile_metrics import parse_processes, select_processes, take_reports, resource_frame
from monomark_profile_usage import read_usage


HEADER = """# Benchmark start

This synthetic document tests inline `code`, **emphasis**, and local reading.

```swift
let enabled = true
print(enabled)
```

$$x^2+y^2=z^2$$

```mermaid
flowchart LR
A[Read] --> B[Understand]
```

![Synthetic two-color figure](figure.png)

"""


def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def make_fixtures(root):
    root.mkdir()
    (root / "Empty").mkdir()
    (root / "Intro.md").write_text("# Benchmark intro\n\nReady.\n")
    row = b"\0" + b"\xff\0\0" * 1000 + b"\0\0\xff" * 1000
    png = b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", struct.pack(">IIBBBBB", 2000, 1200, 8, 2, 0, 0, 0))
    png += png_chunk(b"IDAT", zlib.compress(row * 1200)) + png_chunk(b"IEND", b"")
    (root / "figure.png").write_bytes(png)
    for index, size in enumerate((1, 10), start=1):
        tail = f"\n\n## End of document\n\nEND_PROFILE_{index}\n"
        with (root / f"{size}MiB.md").open("w") as source:
            source.write(HEADER)
            written, paragraph = len(HEADER.encode()), 0
            while written < size * 1024 * 1024 - len(tail):
                text = (f"Paragraph {paragraph}. Read **structured Markdown** with `inline code`. "
                        + "Local documents retain their source while the reader shows formatted text. " * 3 + "\n\n")
                source.write(text)
                written += len(text.encode())
                paragraph += 1
            source.write(tail)
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in root.glob("*.md")}


def snapshot(pid):
    listing = subprocess.run(["ps", "-axo", "pid=,cputime=,rss=,comm="],
                             capture_output=True, text=True, check=True).stdout
    rows = select_processes(parse_processes(listing), pid)
    return {key: {**row, "usage": read_usage(key)} for key, row in rows.items()}


def accumulate(state, rows):
    state["lastRows"] = rows
    for pid, row in rows.items():
        old = state["known"].get(pid)
        if old and old["cpu_seconds"] > row["cpu_seconds"]:
            state["counterReset"] = True
        state["known"][pid] = row
    frame = resource_frame(rows, state["appPID"])
    total = frame["physicalBytes"]
    group = state["resources"].setdefault(state["profile"], {"samples": 0, "peakObservedPhysicalUpperBoundBytes": 0,
                                                          "peakResidentSumBytes": 0, "missingPhysicalSamples": 0,
                                                          "peakObservedAppPhysicalBytes": 0})
    group["samples"] += 1
    if frame["appPhysicalBytes"] is not None:
        group["peakObservedAppPhysicalBytes"] = max(group["peakObservedAppPhysicalBytes"], frame["appPhysicalBytes"])
    group["peakResidentSumBytes"] = max(group["peakResidentSumBytes"], sum(r["rss_bytes"] for r in rows.values()))
    if total is None:
        group["missingPhysicalSamples"] += 1
    else:
        group["peakObservedPhysicalUpperBoundBytes"] = max(group["peakObservedPhysicalUpperBoundBytes"], total)
    frame["cpu"] = sum(r["cpu_seconds"] for r in state["known"].values())
    return {"time": time.monotonic(), **frame}


def receive(state, report, frame):
    if "phase" not in report:
        state["native"] = report
        return
    profile, phase = report["profile"], report["phase"]
    state["profile"] = profile
    if phase == "idle-start":
        state["idleStarts"][profile] = frame
    if phase == "idle-end":
        start = state["idleStarts"].get(profile)
        if start:
            seconds = frame["time"] - start["time"]
            cpu = 100 * (frame["cpu"] - start["cpu"]) / seconds if seconds > 0 else None
            state["resources"][profile]["idleCpuUpperBoundPercentOfOneCore"] = cpu
            state["resources"][profile]["idlePhysicalUpperBoundBytes"] = frame["physicalBytes"]
            if start["appCpu"] is not None and frame["appCpu"] is not None and seconds > 0:
                state["resources"][profile]["idleAppCpuPercentOfOneCore"] = 100 * (frame["appCpu"] - start["appCpu"]) / seconds
            state["resources"][profile]["idleAppPhysicalBytes"] = frame["appPhysicalBytes"]


def read_reports(selector, process, decoder, pending):
    data = b""
    if selector.select(timeout=0.05):
        data = os.read(process.stdout.fileno(), 65536)
    elif process.poll() is not None:
        data = os.read(process.stdout.fileno(), 65536)
    pending += decoder.decode(data)
    if len(pending) > 8 * 1024 * 1024:
        raise ValueError("Native report exceeds its output limit")
    reports, pending = take_reports(pending)
    return reports, pending


def monitor(process, timeout):
    state = {"appPID": process.pid, "profile": "startup", "known": {}, "lastRows": {}, "resources": {}, "idleStarts": {}, "counterReset": False}
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    decoder = codecs.getincrementaldecoder("utf-8")()
    pending, start = "", time.monotonic()
    try:
        while time.monotonic() - start < timeout:
            reports, pending = read_reports(selector, process, decoder, pending)
            for report in reports:
                if report.get("phase") == "open-start":
                    state["profile"] = report["profile"]
            frame = accumulate(state, snapshot(process.pid))
            for report in reports:
                receive(state, report, frame)
            if process.poll() is not None and "native" in state:
                return state
        raise TimeoutError("Native workload did not return a complete report in time")
    finally:
        selector.close()


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def public_hardware():
    def value(key):
        return subprocess.run(["sysctl", "-n", key], capture_output=True, text=True, check=True).stdout.strip()
    return {"model": value("machdep.cpu.brand_string"), "memoryBytes": int(value("hw.memsize")),
            "logicalCores": int(value("hw.ncpu")), "osVersion": platform.mac_ver()[0]}


def result(state, unchanged, process):
    native = state.get("native", {})
    return {"functionalPassed": native.get("passed") is True and unchanged,
            "measurementComplete": bool(native.get("profiles")) and not state["counterReset"],
            "sourceUnchanged": unchanged, "exitCode": process.returncode, "hardware": public_hardware(),
            "native": native, "resources": state["resources"],
            "processesObserved": [{"pid": p, "name": r["command"].rsplit("/", 1)[-1], "usage": r["usage"]}
                                  for p, r in state["known"].items()],
            "attribution": "Main app plus every WebKit helper is a conservative upper bound. Other applications' WebKit helpers are included.",
            "limitations": "Sampled peaks are not guaranteed instantaneous peaks. Hardware-specific release budgets and calibrated energy remain separate."}


def run(app, output, timeout):
    with tempfile.TemporaryDirectory(prefix="monomark-profile-") as directory:
        root = Path(directory)
        fixtures = root / "input"
        hashes = make_fixtures(fixtures)
        temporary = root / "app-temp"
        temporary.mkdir()
        environment = {**os.environ, "TMPDIR": str(temporary) + "/"}
        with output.with_suffix(".native.log").open("w") as errors:
            process = subprocess.Popen([str(app), "--smoke-test", "-", "--performance-smoke", "--performance-input", str(fixtures)],
                                       stdout=subprocess.PIPE, stderr=errors, env=environment)
            try:
                state = monitor(process, timeout)
                process.wait(timeout=10)
                unchanged = all(hashlib.sha256((fixtures / name).read_bytes()).hexdigest() == digest
                                for name, digest in hashes.items())
                return result(state, unchanged, process)
            finally:
                stop(process)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--timeout", type=float, default=120)
    args = parser.parse_args()
    if sys.platform != "darwin":
        parser.error("Native profiling requires macOS")
    app = args.app.resolve()
    if app.is_dir():
        app = app / "Contents/MacOS/MonoMark"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    report = run(app, args.output, args.timeout)
    args.output.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    print(json.dumps({"functionalPassed": report["functionalPassed"], "output": str(args.output)}))
    return 0 if report["functionalPassed"] and report["measurementComplete"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
