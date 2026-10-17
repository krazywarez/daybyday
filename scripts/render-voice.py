"""Render DayByDay's spoken sentences as Kokoro af_heart voice clips.

Runs on a Mac only, never in the app. Setup, in a scratch folder outside the repo:

    uv venv --python 3.12 venv
    uv pip install --python venv/bin/python kokoro==0.9.4 soundfile \
        en_core_web_sm@https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl

Export the sentence list with the ReviewExport test suite (EXPORT_DIR/lines.txt), then:

    venv/bin/python -I scripts/render-voice.py lines.txt DayByDay/Voice [--redo "Sentence." ...]

Each sentence becomes <first 16 hex digits of its SHA-256>.aac (mono AAC in
ADTS, 24 kHz, 32 kbps; ADTS saves ~3.7 KB per clip over .m4a/.caf headers). Existing clips are kept unless named with --redo, which re-renders
them with the next seed. Clips no longer listed are deleted, and
voice-manifest.json is rewritten.
"""
import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from misaki import espeak


class NoFallback:
    """Run without espeak-ng: the espeakng-loader wheel exits the process when
    used, and the spec calls for misaki's dictionary only."""

    def __init__(self, *args, **kwargs):
        raise RuntimeError("espeak fallback disabled")


espeak.EspeakFallback = NoFallback

from kokoro import KPipeline  # noqa: E402

# Words misaki's dictionary lacks, in misaki's US phoneme set. Without espeak,
# a missing word renders no audio, so every such word must be listed here.
PRONUNCIATIONS = {
    "broccoli": "bɹˈɑkəli",
    "orange": "ˈɔɹənʤ",
}

VOICE = "af_heart"
SPEED = 0.9
RATE = 24_000
MARGIN = int(0.04 * RATE)


def measured_seconds(path: Path) -> float:
    """Playback length of the encoded clip. ADTS keeps the encoder's ~90 ms of
    lead-in silence, so this is longer than the rendered audio."""
    out = subprocess.run(["afinfo", str(path)], capture_output=True, text=True, check=True).stdout
    line = next(l for l in out.splitlines() if l.strip().startswith("audio packets:"))
    return round(int(line.split(":")[1]) * 1024 / RATE, 3)


def clip_name(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()[:16] + ".aac"


def trim(audio: np.ndarray) -> np.ndarray:
    """Cut leading and trailing silence, keeping 40 ms on each side."""
    loud = np.flatnonzero(np.abs(audio) > 0.01 * np.abs(audio).max())
    if loud.size == 0:
        return audio
    start, end = max(loud[0] - MARGIN, 0), min(loud[-1] + MARGIN, len(audio))
    return audio[start:end]


# Letter names, in misaki's US phoneme set, used wherever a letter is meant
# ("b", "b is for ball", "the letter b", "That's b!"). Kokoro reads a lone
# letter poorly, and reads "a" as the article "uh".
LETTERS = {
    "a": "ˈA", "b": "bˈi", "c": "sˈi", "d": "dˈi", "e": "ˈi", "f": "ˈɛf", "g": "ʤˈi",
    "h": "ˈAʧ", "i": "ˈI", "j": "ʤˈA", "k": "kˈA", "l": "ˈɛl", "m": "ˈɛm", "n": "ˈɛn",
    "o": "ˈO", "p": "pˈi", "q": "kjˈu", "r": "ˈɑɹ", "s": "ˈɛs", "t": "tˈi", "u": "jˈu",
    "v": "vˈi", "w": "dˈʌbəljˌu", "x": "ˈɛks", "y": "wˈI", "z": "zˈi",
}
LETTER_CONTEXTS = [r"^([a-z])(?=\.?$)", r"^([a-z])(?= is for )", r"(?<=letter )([a-z])\b", r"(?<=That's )([a-z])(?=!)"]

# Short lines rendered alone start with a breath or an "uh". Each sentence is
# rendered after this carrier and cut out at its first word.
CARRIER = "And now, "
CARRIER_TOKENS = 3
PRE_ROLL = 0.04


def with_pronunciations(text: str) -> str:
    """Mark listed words with Kokoro's inline phoneme syntax, [word](/phonemes/)."""
    for word, phonemes in PRONUNCIATIONS.items():
        text = re.sub(rf"\b({word})\b", rf"[\1](/{phonemes}/)", text, flags=re.IGNORECASE)
    for pattern in LETTER_CONTEXTS:
        text = re.sub(pattern, lambda m: f"[{m.group(1)}](/{LETTERS[m.group(1)]}/)", text)
    return text


def render(pipeline: KPipeline, text: str, seed: int) -> np.ndarray:
    """Render after the carrier and keep only the sentence, from 40 ms before
    its first word to the end of its last token."""
    torch.manual_seed(seed)
    results = list(pipeline(CARRIER + with_pronunciations(text), voice=VOICE, speed=SPEED))
    if not results:
        raise RuntimeError(f"no audio for {text!r} (a word missing from the dictionary?)")
    if len(results) != 1 or not results[0].tokens or results[0].tokens[CARRIER_TOKENS].start_ts is None:
        raise RuntimeError(f"cannot cut {text!r} out of its carrier")
    r = results[0]
    audio = np.asarray(r.audio)
    start = max(int((r.tokens[CARRIER_TOKENS].start_ts - PRE_ROLL) * RATE), 0)
    end = min(int(r.tokens[-1].end_ts * RATE) + MARGIN, len(audio))
    clip = audio[start:end]
    fade = int(0.01 * RATE)
    clip[:fade] *= np.linspace(0, 1, fade)
    return trim(clip)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("lines", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--redo", action="append", default=[], help="sentence to re-render with the next seed")
    parser.add_argument("--remeasure", action="store_true", help="re-read every kept clip's duration")
    args = parser.parse_args()

    lines = [l for l in args.lines.read_text().splitlines() if l.strip()]
    unknown = [t for t in args.redo if t not in lines]
    if unknown:
        parser.error(f"--redo text not in {args.lines}: {unknown}")
    args.out.mkdir(parents=True, exist_ok=True)
    manifest_path = args.out / "voice-manifest.json"
    old = {e["text"]: e for e in json.loads(manifest_path.read_text())} if manifest_path.exists() else {}

    pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    entries = []
    with tempfile.TemporaryDirectory() as tmp:
        for i, text in enumerate(lines):
            name = clip_name(text)
            seed = old.get(text, {}).get("seed", 0)
            if text in args.redo:
                seed += 1
            elif text in old and (args.out / name).exists():
                entry = dict(old[text])
                if args.remeasure:
                    entry["seconds"] = measured_seconds(args.out / name)
                entries.append(entry)
                continue
            audio = render(pipeline, text, seed)
            wav = Path(tmp) / "clip.wav"
            sf.write(wav, audio, RATE)
            subprocess.run(["afconvert", "-f", "adts", "-d", "aac", "-b", "32000", "-c", "1",
                            str(wav), str(args.out / name)], check=True)
            entries.append({"text": text, "file": name, "seconds": measured_seconds(args.out / name), "seed": seed})
            if i % 100 == 0:
                print(f"{i}/{len(lines)} {text}", flush=True)
                write_manifest(manifest_path, entries + [e for t, e in old.items() if t not in {x["text"] for x in entries}])

    keep = {e["file"] for e in entries}
    for stale in [*args.out.glob("*.aac"), *args.out.glob("*.m4a")]:
        if stale.name not in keep:
            stale.unlink()
    write_manifest(manifest_path, entries)
    print(f"{len(entries)} clips")


def write_manifest(path: Path, entries: list) -> None:
    """Written as rendering goes, so an interrupted run resumes."""
    path.write_text(json.dumps(sorted(entries, key=lambda e: e["text"]), indent=1, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
