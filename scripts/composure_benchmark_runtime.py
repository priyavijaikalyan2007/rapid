# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 7a6a1f18-cb76-4ec8-9477-50b6844a38a6
# Created: 2026
# COMPONENT: Optional Mac MLX benchmark adapter
# PURPOSE: Load verified local weights and generate bounded fresh responses without remote inference or tools.
# RELATES: composure_model_benchmark.py, composure_benchmark.requirements.txt
# FLOW: Pinned local model -> fresh template and cache -> bounded stream -> typed benchmark parser.

"""The adapter owns one model. Calls are serial and the containing worker has a five-minute watchdog."""

import importlib.metadata
import json
import os
from pathlib import Path
import platform
import resource
import time

JSON_REPLY_PREFIX = '{"action":'


def tokenizer_configuration(model_config: dict) -> dict:
    """Apply Mistral's supported regex correction only to its family and keep tokenizer loading offline."""
    options = {"trust_remote_code": False, "local_files_only": True}
    if model_config.get("model_type") in ("mistral3", "ministral3"):
        options["fix_mistral_regex"] = True
    return options


def render_prompt(tokenizer, policy: str, prompt: str, *, reply_prefix: str = JSON_REPLY_PREFIX) -> str:
    """Start the structured response before generation. The full response remains subject to strict parsing."""
    messages = [{"role": "system", "content": policy}, {"role": "user", "content": prompt}]
    rendered = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True,
                                             enable_thinking=False)
    return rendered + reply_prefix


class MLXBenchmarkRuntime:
    """Keep model imports optional and network-disabled before initializing the MLX library."""

    def __init__(self, model_path: Path, *, reply_prefix: str = JSON_REPLY_PREFIX) -> None:
        self._reply_prefix = reply_prefix
        cache = Path(__file__).resolve().parents[1] / "local" / "composure-benchmark" / "hf-home"
        os.environ.update({"HF_HOME": str(cache), "HF_HUB_OFFLINE": "1", "TRANSFORMERS_OFFLINE": "1",
                           "HF_HUB_DISABLE_IMPLICIT_TOKEN": "1"})
        import mlx.core as mx
        from mlx_lm import load, stream_generate
        from mlx_lm.sample_utils import make_sampler

        self._mx = mx
        self._stream_generate = stream_generate
        self._sampler = make_sampler(temp=0.0)
        mx.set_memory_limit(16 * 1024 ** 3)
        mx.set_cache_limit(1024 ** 3)
        mx.reset_peak_memory()
        started = time.monotonic()
        config = json.loads((model_path / "config.json").read_text())
        self._tokenizer_options = tokenizer_configuration(config)
        self._model, self._tokenizer = load(str(model_path.resolve(strict=True)),
                                             tokenizer_config=self._tokenizer_options,
                                             trust_remote_code=False)
        self._load_seconds = time.monotonic() - started
        self._warmup_seconds = 0.0
        self._warmup_status = "notRun"
        self._model_type = config["model_type"]

    def warmup(self, policy: str) -> None:
        """Record one neutral invented warmup separately from quality and latency cases."""
        started = time.monotonic()
        try:
            self.generate(policy, json.dumps({"currentSpeech": "The review time is confirmed. Thank you."}))
            self._warmup_status = "completed"
        except TimeoutError:
            self._warmup_status = "deadlineExceeded"
        self._warmup_seconds = time.monotonic() - started

    def generate(self, policy: str, prompt: str) -> str:
        """Create a fresh request and cache. The stream checks a cooperative six-second deadline."""
        rendered = render_prompt(self._tokenizer, policy, prompt, reply_prefix=self._reply_prefix)
        if len(self._tokenizer.encode(rendered, add_special_tokens=False)) > 2048:
            raise ValueError("Prompt exceeds its token budget.")
        parts = [self._reply_prefix]
        byte_count = len(self._reply_prefix.encode("utf-8"))
        started = time.monotonic()
        stream = self._stream_generate(self._model, self._tokenizer, rendered, max_tokens=192,
                                        sampler=self._sampler, max_kv_size=4096, prefill_step_size=512)
        try:
            for part in stream:
                if time.monotonic() - started > 6:
                    raise TimeoutError("Generation deadline exceeded.")
                byte_count += len(part.text.encode("utf-8"))
                if byte_count > 4096:
                    raise ValueError("Response exceeds its byte budget.")
                parts.append(part.text)
        finally:
            stream.close()
            self._mx.clear_cache()
        return "".join(parts)

    def metrics(self) -> dict:
        """Report measured prototype memory and versions without model requests or application data."""
        packages = ("mlx", "mlx-lm", "transformers", "huggingface-hub")
        versions = {name: importlib.metadata.version(name) for name in packages}
        return {"versions": versions, "macOS": platform.mac_ver()[0], "architecture": platform.machine(),
                "loadSeconds": self._load_seconds, "warmupSeconds": self._warmup_seconds,
                "warmupStatus": self._warmup_status, "mlxPeakBytes": self._mx.get_peak_memory(),
                "processPeakBytes": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
                "maxOutputTokens": 192, "maxInputTokens": 2048, "temperature": 0.0,
                "requestedThinking": False, "adapterVersion": 5, "replyPrefix": self._reply_prefix,
                "tokenizerOptions": self._tokenizer_options,
                "memoryLimitBytes": 16 * 1024 ** 3}
