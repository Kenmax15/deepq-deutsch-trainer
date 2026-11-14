extends Node
## Interface strings (autoload "I18n"). German learning content lives in the
## mission JSON files; this file only holds the French/English UI.

const STRINGS := {
	"app_title": {"fr": "DeepQ Deutsch Trainer", "en": "DeepQ Deutsch Trainer"},
	"app_sub": {"fr": "Life Simulator · prototype pilote", "en": "Life Simulator · pilot prototype"},
	"start": {"fr": "Commencer la mission", "en": "Start the mission"},
	"resume": {"fr": "Reprendre", "en": "Resume"},
	"restart": {"fr": "Recommencer", "en": "Start over"},
	"mode": {"fr": "Mode", "en": "Mode"},
	"mode_learning": {"fr": "Apprentissage", "en": "Learning"},
	"mode_mission": {"fr": "Mission", "en": "Mission"},
	"mode_real": {"fr": "Vie réelle", "en": "Real life"},
	"mode_learning_d": {"fr": "Qubi t’aide, traductions et réponses guidées.", "en": "Qubi helps, translations and guided answers."},
	"mode_mission_d": {"fr": "Atteins l’objectif ; indices sur demande (H).", "en": "Reach the goal; hints on request (H)."},
	"mode_real_d": {"fr": "Aide minimale, vitesse naturelle, bruit ambiant.", "en": "Minimal help, natural speed, ambient noise."},
	"controls": {"fr": "ZQSD / WASD ou flèches : se déplacer · Maj : courir · clic droit + souris : caméra · E : parler · H : indice · R : réécouter · Échap : menu",
		"en": "WASD or arrows: move · Shift: run · right-click + mouse: camera · E: talk · H: hint · R: replay · Esc: menu"},
	"objectives": {"fr": "Objectifs", "en": "Objectives"},
	"talk_seller": {"fr": "Parler à la vendeuse", "en": "Talk to the shop assistant"},
	"talk_passerby": {"fr": "Demander le chemin", "en": "Ask the way"},
	"ask_way": {"fr": "Entschuldigung, wo ist die Bäckerei?", "en": "Entschuldigung, wo ist die Bäckerei?"},
	"you": {"fr": "Vous", "en": "You"},
	"seller": {"fr": "Frau Becker (vendeuse)", "en": "Frau Becker (shop assistant)"},
	"passerby": {"fr": "Passant", "en": "Passer-by"},
	"replay": {"fr": "Réécouter", "en": "Replay"},
	"slow": {"fr": "Lentement", "en": "Slowly"},
	"hint": {"fr": "Indice", "en": "Hint"},
	"translate": {"fr": "Traduction", "en": "Translation"},
	"your_answer": {"fr": "Ta réponse en allemand…", "en": "Your answer in German…"},
	"send": {"fr": "Envoyer", "en": "Send"},
	"guided": {"fr": "Réponses guidées", "en": "Guided answers"},
	"hear_model": {"fr": "Écouter un modèle", "en": "Hear a model answer"},
	"continue": {"fr": "Continuer", "en": "Continue"},
	"how_much": {"fr": "Combien payes-tu ?", "en": "How much do you pay?"},
	"correct": {"fr": "Bravo !", "en": "Well done!"},
	"partial": {"fr": "Presque !", "en": "Almost!"},
	"wrong": {"fr": "Pas tout à fait…", "en": "Not quite…"},
	"not_understood": {"fr": "La vendeuse n’a pas compris. Essaie une autre formulation ou utilise les réponses guidées.",
		"en": "The shop assistant didn’t understand. Try another wording or use the guided answers."},
	"settings": {"fr": "Réglages", "en": "Settings"},
	"audio": {"fr": "Audio", "en": "Audio"},
	"vol_master": {"fr": "Volume général", "en": "Master volume"},
	"vol_voice": {"fr": "Voix", "en": "Voices"},
	"vol_sfx": {"fr": "Bruitages", "en": "Sound effects"},
	"vol_ambience": {"fr": "Ambiance", "en": "Ambience"},
	"vol_music": {"fr": "Musique", "en": "Music"},
	"immersion": {"fr": "Ambiance sonore", "en": "Soundscape"},
	"imm_easy": {"fr": "Facile (bruit réduit)", "en": "Easy (less noise)"},
	"imm_normal": {"fr": "Normale", "en": "Normal"},
	"imm_dense": {"fr": "Immersion dense", "en": "Dense immersion"},
	"subtitles": {"fr": "Sous-titres allemands", "en": "German subtitles"},
	"translation": {"fr": "Traduction affichée", "en": "Show translation"},
	"ui_lang": {"fr": "Langue de l’interface", "en": "Interface language"},
	"quality": {"fr": "Qualité graphique", "en": "Graphics quality"},
	"q_low": {"fr": "Basse", "en": "Low"},
	"q_medium": {"fr": "Moyenne", "en": "Medium"},
	"q_high": {"fr": "Élevée", "en": "High"},
	"q_ultra": {"fr": "Ultra (éclairage global)", "en": "Ultra (global illumination)"},
	"back": {"fr": "Reprendre le jeu", "en": "Back to the game"},
	"save": {"fr": "Sauvegarder", "en": "Save"},
	"saved": {"fr": "Partie sauvegardée.", "en": "Game saved."},
	"reset": {"fr": "Effacer la progression", "en": "Erase progress"},
	"quit": {"fr": "Quitter", "en": "Quit"},
	"result_title": {"fr": "Mission accomplie !", "en": "Mission complete!"},
	"score": {"fr": "Réussite du premier coup", "en": "Right first time"},
	"hints_used": {"fr": "Indices utilisés", "en": "Hints used"},
	"errors": {"fr": "À retravailler", "en": "To work on"},
	"no_errors": {"fr": "Aucune erreur, excellent !", "en": "No mistakes, excellent!"},
	"vocab": {"fr": "Vocabulaire de la mission", "en": "Mission vocabulary"},
	"grammar": {"fr": "Points de grammaire", "en": "Grammar points"},
	"replay_mission": {"fr": "Rejouer la mission", "en": "Play again"},
	"explore": {"fr": "Continuer à explorer", "en": "Keep exploring"},
	"you_said": {"fr": "Tu as dit", "en": "You said"},
	"qubi_welcome": {"fr": "Hallo ! Je suis Qubi. Ta mission : acheter du pain à la boulangerie Becker, un peu plus loin sur la droite.",
		"en": "Hallo! I’m Qubi. Your mission: buy bread at the Becker bakery, a little further on the right."},
	"qubi_enter": {"fr": "Te voilà dans la boulangerie ! Approche-toi du comptoir et appuie sur E pour parler à Frau Becker.",
		"en": "You’re in the bakery! Walk up to the counter and press E to talk to Frau Becker."},
	"qubi_pay": {"fr": "Écoute bien le prix, puis choisis le montant.", "en": "Listen carefully to the price, then pick the amount."},
	"qubi_done": {"fr": "Super, tu as acheté ton pain en allemand ! Regarde ton bilan.", "en": "Great, you bought your bread in German! Check your summary."},
	"qubi_cheer": {"fr": "Bien joué !", "en": "Nice one!"},
	"qubi_oops": {"fr": "Pas grave, on apprend en se trompant.", "en": "No problem, mistakes are how we learn."},
	"qubi_hint_cost": {"fr": "Indice (noté dans le bilan, sans pénalité) :", "en": "Hint (noted in the summary, no penalty):"},
}


func lang() -> String:
	return GameState.get_setting("ui_lang")


func t(key: String) -> String:
	var entry: Dictionary = STRINGS.get(key, {})
	return entry.get(lang(), entry.get("en", key))


## Picks the current UI language from a {"fr": .., "en": ..} dictionary.
func pick(d) -> String:
	if typeof(d) != TYPE_DICTIONARY:
		return str(d)
	return d.get(lang(), d.get("en", d.get("fr", "")))
