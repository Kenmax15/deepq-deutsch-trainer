"""Generate the German voice lines of a mission with Piper TTS (offline).

Voices (both trained on CC0 datasets, see ASSETS.md):
  seller   -> de_DE-kerstin-low   (female)
  passerby -> de_DE-thorsten-high (male)
  model    -> de_DE-thorsten-high (model answers for the learner)

Usage (from the repository root):
    pip install piper-tts
    python tools/gen_voices.py --voices DIR [--mission web/data/brot_kaufen.json]

DIR must contain de_DE-kerstin-low.onnx(.json) and de_DE-thorsten-high.onnx(.json),
downloadable from https://huggingface.co/rhasspy/piper-voices (de/de_DE/...).
For every line two files are written to build/voice_wav/<mission>/:
<id>.wav (natural speed) and <id>_slow.wav (about 40 % slower, same pitch),
then converted to web/audio/voice/<id>.mp3 with ffmpeg (mono, 64 kbit/s).
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOICE_FILES = {
    "seller": "de_DE-kerstin-low.onnx",
    "passerby": "de_DE-thorsten-high.onnx",
    "model": "de_DE-thorsten-high.onnx",
}
SPEEDS = {"": 1.0, "_slow": 1.45}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--voices", required=True, help="folder with the Piper .onnx voices")
    ap.add_argument("--mission", default=str(ROOT / "web/data/brot_kaufen.json"))
    args = ap.parse_args()

    mission = json.loads(Path(args.mission).read_text(encoding="utf-8"))
    out = ROOT / "build" / "voice_wav" / mission["id"]
    out.mkdir(parents=True, exist_ok=True)
    for line_id, line in mission["lines"].items():
        model = Path(args.voices) / VOICE_FILES[line["voice"]]
        for suffix, scale in SPEEDS.items():
            wav = out / f"{line_id}{suffix}.wav"
            subprocess.run(
                [sys.executable, "-m", "piper", "-m", str(model), "-f", str(wav),
                 "--length-scale", str(scale), "--sentence-silence", "0.15"],
                input=line["de"].encode("utf-8"), check=True,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"{line_id:22s} {line['voice']:9s} {line['de']}")


if __name__ == "__main__":
    main()
