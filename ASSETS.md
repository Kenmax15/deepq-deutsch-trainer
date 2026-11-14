# Asset origin and licences (§9 of the specification)

Every asset in the pilot may be used commercially. No asset under a non-commercial (NC) licence or with a mandatory attribution clause is used.

| Asset | Location | Source | Licence | Status |
|---|---|---|---|---|
| Roads, pavements, buildings, trees, street lamps | `godot/assets/kenney/city/` | Kenney, *Starter Kit City Builder* — github.com/KenneyNL/Starter-Kit-City-Builder | CC0 1.0 for the models (the sample code is MIT and not used) | provisional; style to be harmonised |
| Vehicles (vans, motorbike) | `godot/assets/kenney/vehicles/` | Kenney, *Starter Kit Racing* — github.com/KenneyNL/Starter-Kit-Racing | CC0 1.0 | provisional |
| Bakery, interior, bread, street furniture | generated in code (`scripts/world.gd`) | DeepQ (this project) | owned by the project | provisional |
| Human characters (player, shop assistant, passers-by, customer) | `godot/assets/quaternius/men/` and `.../women/` (7 glTF models) | Quaternius, *Ultimate Modular Men* (Feb 2022) and *Ultimate Modular Women* (Apr 2022) — quaternius.com | CC0 1.0 (`LICENSE-Quaternius-CC0.txt`) | stylised; more realistic avatars planned (§5.1) |
| Fallback characters | generated in code (`scripts/humanoid.gd`) | DeepQ (this project) | owned by the project | used only if a model is missing |
| Shop assistant's apron | generated in code (`scripts/character_model.gd`) | DeepQ (this project) | owned by the project | provisional |
| Qubi (mascot), icon | `scripts/qubi.gd`, `godot/icon.svg` | DeepQ (this project) | owned by the project | needs approval against the brand guidelines |
| Sound effects, ambiences, café music | `godot/assets/audio/sfx/` | synthesised by `tools/gen_sfx.py` (numpy, no samples) | owned by the project | provisional |
| Shop assistant's voice | `godot/assets/audio/voice/brot_kaufen/s_*.wav` | Piper TTS, voice `de_DE-kerstin-low` — huggingface.co/rhasspy/piper-voices | CC0 dataset; Piper is MIT | synthetic; replace with recorded voices if desired |
| Passers-by and model-answer voices | `.../p_*.wav`, `.../m_*.wav` | Piper TTS, voice `de_DE-thorsten-high` | Thorsten-Voice CC0 dataset; Piper is MIT | synthetic; replace with recorded voices if desired |
| Teaching content (lines, translations, rules, vocabulary) | `godot/data/missions/brot_kaufen.json` | written for this project | owned by the project | `draft-to-review`: a teacher must review it |
| Engine | — | Godot Engine 4.5.1 | MIT | — |

The Piper voice model files (`.onnx`, about 60–110 MB) are not committed; only the generated audio files are. The header of `tools/gen_voices.py` explains how to regenerate them.
