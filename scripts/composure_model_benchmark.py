#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: e423eaaa-b5de-4896-92e4-ea9c6305198b
# Created: 2026
# COMPONENT: Invented local model benchmark
# PURPOSE: Compare bounded local inference without application data or a production model dependency.
# RELATES: composure_benchmark_runtime.py, LocalModelBenchmarkTests
# FLOW: Exported invented fixtures -> local serial inference -> strict replies -> Core replay.

"""A developer benchmark. Optional MLX packages load only inside the bounded worker process."""

import argparse
from collections.abc import Callable
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
import time

ACTIONS = frozenset({"noAction", "clarify", "askFirst", "decisionFocus", "dontGuess", "pause", "rephrase"})
MAX_FIXTURE_BYTES = 262144
MAX_INPUT_BYTES = 8192
MAX_RESPONSE_BYTES = 4096
LIVE_DEADLINE_SECONDS = 6.0


def _object(pairs: list) -> dict:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Repeated JSON field.")
        result[key] = value
    return result


def _invalid_constant(_value: str):
    raise ValueError("Non-finite JSON number.")


def _decode(text: str) -> dict:
    try:
        value = json.loads(text, object_pairs_hook=_object, parse_constant=_invalid_constant)
    except (RecursionError, json.JSONDecodeError):
        raise ValueError("Invalid JSON document.") from None
    if type(value) is not dict:
        raise ValueError("Expected a JSON object.")
    return value


def _number(value, maximum: float) -> bool:
    return type(value) in (int, float) and math.isfinite(value) and 0 <= value <= maximum


def parse_reply(text: str) -> dict:
    """Accept only a complete bounded reply. Core independently validates instruction language later."""
    if type(text) is not str or len(text.encode("utf-8")) > MAX_RESPONSE_BYTES:
        raise ValueError("Response exceeds its text limit.")
    reply = _decode(text)
    if set(reply) != {"action", "confidence", "instruction"}:
        raise ValueError("Unexpected response fields.")
    if type(reply["action"]) is not str or reply["action"] not in ACTIONS:
        raise ValueError("Unsupported action.")
    if not _number(reply["confidence"], 1):
        raise ValueError("Invalid confidence.")
    instruction = reply["instruction"]
    if type(instruction) is not str or len(instruction.encode("utf-8")) > 160:
        raise ValueError("Invalid instruction text.")
    if reply["action"] == "noAction" and instruction != "":
        raise ValueError("Silence must have no instruction.")
    return reply


def _validate_case(case: dict, identifiers: set) -> None:
    if type(case) is not dict or not {"id", "group", "offset", "input", "expected"} <= set(case):
        raise ValueError("Invalid case shape.")
    identifier = case["id"]
    if type(identifier) is not str or not identifier or len(identifier) > 96 or identifier in identifiers:
        raise ValueError("Invalid or repeated case identifier.")
    identifiers.add(identifier)
    if type(case["group"]) is not str or not 1 <= len(case["group"]) <= 96:
        raise ValueError("Invalid case group.")
    if not _number(case["offset"], 600) or type(case["input"]) is not dict:
        raise ValueError("Invalid case input.")
    encoded = json.dumps(case["input"], ensure_ascii=False, allow_nan=False)
    if len(encoded.encode("utf-8")) > MAX_INPUT_BYTES:
        raise ValueError("Case input exceeds its byte limit.")
    expected = case["expected"]
    if type(expected) is not list or any(type(item) is not str or item not in ACTIONS for item in expected):
        raise ValueError("Invalid expected outcomes.")


def _validate_fixtures(value: dict) -> None:
    if type(value.get("version")) is not int or value["version"] != 1 or value.get("dataClass") != "invented":
        raise ValueError("Use the invented fixture exporter.")
    policy = value.get("policy")
    if type(policy) is not str or not policy or len(policy.encode("utf-8")) > MAX_INPUT_BYTES:
        raise ValueError("Invalid benchmark policy.")
    cases = value.get("cases")
    if type(cases) is not list or not 1 <= len(cases) <= 32:
        raise ValueError("Invalid case count.")
    identifiers = set()
    for case in cases:
        _validate_case(case, identifiers)


def load_fixtures(path: Path) -> dict:
    """Read a bounded invented export. No application preference or meeting store is accessed."""
    if path.stat().st_size > MAX_FIXTURE_BYTES:
        raise ValueError("Fixture export exceeds its byte limit.")
    data = path.read_bytes()
    if len(data) > MAX_FIXTURE_BYTES:
        raise ValueError("Fixture export exceeds its byte limit.")
    value = _decode(data.decode("utf-8"))
    _validate_fixtures(value)
    return value


def verify_model(root: Path, model_id: str, manifest_path: Path) -> dict:
    """Verify every approved artifact before the optional inference runtime can load it."""
    if manifest_path.stat().st_size > MAX_FIXTURE_BYTES:
        raise ValueError("Model manifest exceeds its byte limit.")
    manifest = _decode(manifest_path.read_text(encoding="utf-8"))
    matches = [model for model in manifest["models"] if model["id"] == model_id]
    if len(matches) != 1:
        raise ValueError("Select a pinned model from the manifest.")
    model = matches[0]
    root = root.resolve(strict=True)
    expected_weights = set()
    for artifact in model["files"]:
        path = (root / artifact["path"]).resolve()
        if not path.is_relative_to(root) or not path.is_file():
            raise ValueError("Model path escapes its directory.")
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            while chunk := stream.read(1024 * 1024):
                digest.update(chunk)
        if digest.hexdigest() != artifact["sha256"]:
            raise ValueError("Model artifact checksum mismatch.")
        if path.suffix == ".safetensors":
            expected_weights.add(path)
    if set(root.glob("*.safetensors")) != expected_weights:
        raise ValueError("Unexpected model weights.")
    return model


def _run_case(case: dict, policy: str, generate, clock) -> dict:
    result = {key: case[key] for key in ("id", "group", "offset")}
    result.update({"status": "generationFailed", "reply": None})
    started = clock()
    try:
        prompt = json.dumps(case["input"], ensure_ascii=False, sort_keys=True, allow_nan=False, separators=(",", ":"))
        raw = generate(policy, prompt)
        result["status"] = "invalidOutput"
        result["reply"] = parse_reply(raw)
        result["status"] = "ok"
    except TimeoutError:
        result["status"] = "deadlineExceeded"
    except ValueError:
        pass
    except Exception:
        result["status"] = "generationFailed"
    elapsed = clock() - started
    result["elapsedSeconds"] = elapsed if _number(elapsed, 300) else 300.0
    if result["elapsedSeconds"] > LIVE_DEADLINE_SECONDS:
        result["status"] = "deadlineExceeded"
    return result


def run_cases(fixtures: dict, generate: Callable[[str, str], str], clock: Callable[[], float]) -> dict:
    """Run serial fresh requests. Gold labels and case metadata never reach generation."""
    _validate_fixtures(fixtures)
    return {"version": 1, "dataClass": "invented", "liveDeadlineSeconds": LIVE_DEADLINE_SECONDS,
            "cases": [_run_case(case, fixtures["policy"], generate, clock) for case in fixtures["cases"]]}


def _arguments(argv: list[str]):
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--fixtures", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--model-id", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--worker", action="store_true", help=argparse.SUPPRESS)
    return parser.parse_args(argv)


def _worker(args) -> int:
    from composure_benchmark_runtime import MLXBenchmarkRuntime

    fixtures = load_fixtures(args.fixtures)
    if args.output.exists():
        raise ValueError("Select a new output path.")
    manifest = Path(__file__).resolve().parents[1] / "specs" / "composure-model-artifacts.json"
    model = verify_model(args.model_dir, args.model_id, manifest)
    runtime = MLXBenchmarkRuntime(args.model_dir)
    runtime.warmup(fixtures["policy"])
    result = run_cases(fixtures, runtime.generate, time.monotonic)
    result["modelID"] = args.model_id
    result["modelRevision"] = model["revision"]
    result["artifactManifestSHA256"] = hashlib.sha256(manifest.read_bytes()).hexdigest()
    result["fixtureSHA256"] = hashlib.sha256(args.fixtures.read_bytes()).hexdigest()
    result["policySHA256"] = hashlib.sha256(fixtures["policy"].encode("utf-8")).hexdigest()
    result["runtime"] = runtime.metrics()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, ensure_ascii=False, allow_nan=False, indent=2, sort_keys=True)
        stream.write("\n")
    print(f"Benchmark completed: {len(result['cases'])} invented cases.")
    return 0


def main(argv: list[str] | None = None) -> int:
    """Bound a model worker to five minutes, including loading. Fail without raw provider details."""
    argv = sys.argv[1:] if argv is None else argv
    args = _arguments(argv)
    try:
        if args.worker:
            return _worker(args)
        load_fixtures(args.fixtures)
        completed = subprocess.run([sys.executable, str(Path(__file__).resolve()), *argv, "--worker"],
                                   timeout=300, check=False)
        return completed.returncode
    except subprocess.TimeoutExpired:
        print("Benchmark exceeded five minutes. The model worker stopped.", file=sys.stderr)
    except (OSError, ValueError, RuntimeError, ImportError):
        print("Benchmark could not run. Check the fixture export, local model, and pinned environment.",
              file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
