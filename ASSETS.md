# Provenance et licences des ressources (§9 du cahier des charges)

Toutes les ressources du pilote sont commercialisables. Aucune ressource sous licence non commerciale
(NC) ni à attribution obligatoire n'est utilisée.

| Ressource | Emplacement | Source | Licence | Statut |
|---|---|---|---|---|
| Routes, trottoirs, immeubles, arbres, lampadaires | `godot/assets/kenney/city/` | Kenney, *Starter Kit City Builder* — github.com/KenneyNL/Starter-Kit-City-Builder | CC0 1.0 (modèles), code de l'exemple MIT (non utilisé) | provisoire, style à homogénéiser |
| Véhicules (camionnettes, moto) | `godot/assets/kenney/vehicles/` | Kenney, *Starter Kit Racing* — github.com/KenneyNL/Starter-Kit-Racing | CC0 1.0 | provisoire |
| Boulangerie, intérieur, pains, mobilier urbain | généré par code (`scripts/world.gd`) | DeepQ (ce projet) | propriété du projet | provisoire |
| Personnages humains (joueur, vendeuse, passants, client) | `godot/assets/quaternius/men/`, `.../women/` (7 modèles glTF) | Quaternius, *Ultimate Modular Men* (fév. 2022) et *Ultimate Modular Women* (avr. 2022) — quaternius.com | CC0 1.0 (`LICENSE-Quaternius-CC0.txt`) | stylisés ; avatars plus réalistes à prévoir (§5.1) |
| Personnages de repli | générés par code (`scripts/humanoid.gd`) | DeepQ (ce projet) | propriété du projet | utilisés seulement si un modèle manque |
| Tablier de la vendeuse | généré par code (`scripts/character_model.gd`) | DeepQ (ce projet) | propriété du projet | provisoire |
| Qubi (mascotte), icône | `scripts/qubi.gd`, `godot/icon.svg` | DeepQ (ce projet) | propriété du projet | à faire valider par la charte graphique |
| Bruitages, ambiances, musique de café | `godot/assets/audio/sfx/` | synthétisés par `tools/gen_sfx.py` (numpy, aucun échantillon) | propriété du projet | provisoire |
| Voix de la vendeuse | `godot/assets/audio/voice/brot_kaufen/s_*.wav` | Piper TTS, voix `de_DE-kerstin-low` — huggingface.co/rhasspy/piper-voices | jeu de données CC0 ; Piper : MIT | synthèse, à remplacer par des voix enregistrées si souhaité |
| Voix des passants et réponses modèles | `.../p_*.wav`, `.../m_*.wav` | Piper TTS, voix `de_DE-thorsten-high` | jeu de données Thorsten-Voice CC0 ; Piper : MIT | idem |
| Contenu pédagogique (répliques, traductions, règles, vocabulaire) | `godot/data/missions/brot_kaufen.json` | rédigé pour ce projet | propriété du projet | `draft-to-review` : relecture par un enseignant requise |
| Moteur | — | Godot Engine 4.5.1 | MIT | — |

Les fichiers de modèles vocaux Piper (`.onnx`, ~60–110 Mo) ne sont pas versionnés ; seuls les fichiers audio
générés le sont. Pour régénérer : voir l'en-tête de `tools/gen_voices.py`.
