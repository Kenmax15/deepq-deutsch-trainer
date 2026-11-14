"""Generate the German audio of the learning content (words, examples, sentences,
reading texts, grammar examples) with Piper TTS, offline.

    python tools/build_audio.py --voices DIR      (DIR holds de_DE-thorsten-high.onnx + .json)

Needs node (to read the data files) and ffmpeg. Output: web/audio/lex/<id>.mp3 (mono, 48 kbit/s).
A manifest keeps the text of every file, so only new or changed items are generated again.
"""
import argparse, json, subprocess, sys, tempfile, wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "web" / "audio" / "lex"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--voices", required=True)
    args = ap.parse_args()
    from piper import PiperVoice, SynthesisConfig
    items = json.loads(subprocess.run(["node", str(ROOT / "tools" / "audio_items.js")], capture_output=True, text=True, check=True).stdout)
    OUT.mkdir(parents=True, exist_ok=True)
    man_path = OUT / "manifest.json"
    manifest = json.loads(man_path.read_text(encoding="utf-8")) if man_path.exists() else {}
    voice = PiperVoice.load(str(Path(args.voices) / "de_DE-thorsten-high.onnx"))
    cfg = SynthesisConfig(length_scale=1.08)
    todo = [(i, t) for i, t in items if manifest.get(i) != t or not (OUT / f"{i}.mp3").exists()]
    print(f"{len(items)} items, {len(todo)} to generate")
    with tempfile.TemporaryDirectory() as tmp:
        for n, (item_id, text) in enumerate(todo, 1):
            wav = Path(tmp) / "x.wav"
            with wave.open(str(wav), "wb") as w:
                voice.synthesize_wav(text, w, syn_config=cfg)
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-af", "loudnorm=I=-18:TP=-1.5",
                            "-ac", "1", "-ar", "22050", "-b:a", "48k", str(OUT / f"{item_id}.mp3")], check=True)
            manifest[item_id] = text
            if n % 50 == 0:
                print(n, "/", len(todo))
                man_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=0), encoding="utf-8")
    keep = {i for i, _ in items}
    for f in OUT.glob("*.mp3"):
        if f.stem not in keep:
            f.unlink()
            manifest.pop(f.stem, None)
    man_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=0), encoding="utf-8")
    print("done")


if __name__ == "__main__":
    sys.exit(main())
