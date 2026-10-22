"""Render DayByDay's spoken sentences as ElevenLabs Jessica (eleven_v4) voice clips.

Runs on a Mac only, never in the app. Needs Python 3 (no packages) and an API key
with text-to-speech access in ELEVENLABS_API_KEY. Export the sentence list with
the ReviewExport test suite (EXPORT_DIR/lines.txt), then:

    python3 scripts/render-voice-elevenlabs.py lines.txt DayByDay/Voice [--redo "Sentence." ...]
    python3 scripts/render-voice-elevenlabs.py lines.txt DayByDay/Voice --dry-run

Output, file names, manifest and --redo work as in render-voice.py (Kokoro).
--dry-run prints the text each sentence would be sent as, and sends nothing.
"""
import argparse
import array
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import wave
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

VOICE_ID = "cgSgspJ2msm6clMCkdW9"  # Jessica
MODEL = "eleven_v4"
RATE = 24_000
MARGIN = int(0.04 * RATE)
WORKERS = 2

# PraisePhrases.all, plus the other lines said after a success.
EXCITED = {
    "Great job!", "You got it!", "Super!", "Way to go!", "Awesome!", "Yes, that's right!",
    "Nice work!", "You did great!", "Hooray!", "Fantastic!",
    "You did it!", "Happy birthday!", "Today is your birthday!", "Here's your sticker!",
}
GENTLE = re.compile(r"^(That's .+!|Try again[.!]|Let's try again\.|Stay on .+\.)$")
EXCITED_PATTERN = re.compile(r"^You traced .+!$")

# How each letter is written for the voice wherever a letter is meant. A
# lowercase letter is read as its sound ("a" as "uh"); some capitals are too.
LETTERS = {c: c.upper() for c in "abcdefghijklmnopqrstuvwxyz"} | {
    "g": "Gee", "h": "Aitch", "i": "Eye", "u": "You", "w": "Double-you", "y": "Why", "z": "Zee",
}
LETTER_CONTEXTS = [r"^([a-z])(?=\.?$)", r"^([a-z])(?= is for )", r"(?<=letter )([a-z])\b", r"(?<=That's )([a-z])(?=!)"]


def tone(text: str) -> str | None:
    if text in EXCITED or EXCITED_PATTERN.match(text):
        return "excited"
    if GENTLE.match(text):
        return "gently"
    if text.endswith("?"):
        return "curious"
    return None


def spoken(text: str) -> str:
    """The text sent to the voice: letter names spelled out, tone tag in front."""
    for pattern in LETTER_CONTEXTS:
        text = re.sub(pattern, lambda m: LETTERS[m.group(1)], text)
    tag = tone(text)
    return f"[{tag}] {text}" if tag else text


def measured_seconds(path: Path) -> float:
    """Playback length of the encoded clip, including the encoder's lead-in."""
    out = subprocess.run(["afinfo", str(path)], capture_output=True, text=True, check=True).stdout
    line = next(l for l in out.splitlines() if l.strip().startswith("audio packets:"))
    return round(int(line.split(":")[1]) * 1024 / RATE, 3)


def clip_name(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()[:16] + ".aac"


def trim(audio: array.array) -> array.array:
    """Cut leading and trailing silence, keeping 40 ms on each side, with a 10 ms fade-in."""
    peak = max(map(abs, audio), default=0)
    loud = [i for i, x in enumerate(audio) if abs(x) > 0.01 * peak]
    if not loud:
        raise RuntimeError("silent clip")
    clip = audio[max(loud[0] - MARGIN, 0):min(loud[-1] + MARGIN, len(audio))]
    fade = min(int(0.01 * RATE), len(clip))
    for i in range(fade):
        clip[i] = int(clip[i] * i / fade)
    return clip


def render(key: str, text: str, seed: int) -> array.array:
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}?output_format=pcm_{RATE}",
        data=json.dumps({"text": spoken(text), "model_id": MODEL, "seed": seed}).encode(),
        headers={"xi-api-key": key, "Content-Type": "application/json"})
    for attempt in range(8):
        try:
            pcm = urllib.request.urlopen(req, timeout=60).read()
            audio = array.array("h", pcm)  # 16-bit little-endian, as on every Mac
            return trim(audio)
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise RuntimeError(f"{e.code} for {text!r}: {e.read().decode(errors='replace')}") from e
            time.sleep(2 + 2 * attempt)
    raise RuntimeError(f"rate limited: {text!r}")


def encode(audio: array.array, out: Path) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "clip.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(audio.tobytes())
        subprocess.run(["afconvert", "-f", "adts", "-d", "aac", "-b", "32000", "-c", "1",
                        str(wav), str(out)], check=True)


def plan(lines: list, old: dict, out: Path, redo: list) -> tuple[list, list]:
    """Splits lines into manifest entries to keep and (text, seed) pairs to render."""
    kept, todo = [], []
    for text in lines:
        entry = old.get(text)
        if entry and text not in redo and entry.get("engine") == MODEL and (out / entry["file"]).exists():
            kept.append(entry)
        else:
            seed = entry["seed"] + 1 if entry and text in redo else 0
            todo.append((text, seed))
    return kept, todo


def remove_stale(out: Path, keep: set) -> None:
    for stale in [*out.glob("*.aac"), *out.glob("*.m4a")]:
        if stale.name not in keep:
            stale.unlink()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("lines", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--redo", action="append", default=[], help="sentence to re-render with the next seed")
    parser.add_argument("--dry-run", action="store_true", help="print what would be sent, send nothing")
    args = parser.parse_args()

    lines = [l for l in args.lines.read_text().splitlines() if l.strip()]
    unknown = [t for t in args.redo if t not in lines]
    if unknown:
        parser.error(f"--redo text not in {args.lines}: {unknown}")
    if args.dry_run:
        for text in lines:
            print(spoken(text))
        print(f"{sum(len(spoken(t)) for t in lines)} characters", file=sys.stderr)
        return
    key = os.environ["ELEVENLABS_API_KEY"]
    args.out.mkdir(parents=True, exist_ok=True)
    manifest_path = args.out / "voice-manifest.json"
    old = {e["text"]: e for e in json.loads(manifest_path.read_text())} if manifest_path.exists() else {}

    kept, todo = plan(lines, old, args.out, args.redo)

    def job(item):
        text, seed = item
        name = clip_name(text)
        encode(render(key, text, seed), args.out / name)
        return {"text": text, "file": name, "seconds": measured_seconds(args.out / name), "seed": seed, "engine": MODEL}

    done = []
    with ThreadPoolExecutor(WORKERS) as pool:
        for i, entry in enumerate(pool.map(job, todo)):
            done.append(entry)
            if i % 50 == 0:
                print(f"{i}/{len(todo)} {entry['text']}", flush=True)
                fresh = {e["text"] for e in done}
                write_manifest(manifest_path, kept + done + [e for t, e in old.items() if t not in fresh and e not in kept])

    entries = kept + done
    remove_stale(args.out, {e["file"] for e in entries})
    write_manifest(manifest_path, entries)
    print(f"{len(done)} rendered, {len(kept)} kept")


def write_manifest(path: Path, entries: list) -> None:
    """Written as rendering goes, so an interrupted run resumes."""
    path.write_text(json.dumps(sorted(entries, key=lambda e: e["text"]), indent=1, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
