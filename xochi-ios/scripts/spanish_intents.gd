extends RefCounted
## Authored language content. A recognized intention is not a pronunciation score.
const LESSONS := [
	{"intent":"come", "spanish":"Ven", "english":"Come here"},
	{"intent":"wait", "spanish":"Espera", "english":"Wait"},
	{"intent":"boat", "spanish":"Al bote", "english":"Onto the boat"},
	{"intent":"bridge", "spanish":"Al puente", "english":"To the bridge"},
	{"intent":"behind_boat", "spanish":"Detrás del bote", "english":"Behind the boat"},
	{"intent":"now", "spanish":"Ahora", "english":"Now"},
	{"intent":"jump", "spanish":"Salta", "english":"Jump"},
]
const SPOKEN_EXAMPLES := ["Ven", "Espera", "Al bote", "Al puente", "Detrás del bote", "Ahora", "Salta", "Ahora, salta."]
const ALIASES := {
	"ven":["come","es"], "ven aqui":["come","es"], "ven conmigo":["come","es"],
	"come":["come","en"], "come here":["come","en"], "come with me":["come","en"],
	"espera":["wait","es"], "espera aqui":["wait","es"],
	"wait":["wait","en"], "wait here":["wait","en"],
	"al bote":["boat","es"], "ve al bote":["boat","es"], "sube al bote":["boat","es"],
	"onto boat":["boat","en"], "onto the boat":["boat","en"], "go to the boat":["boat","en"], "to the boat":["boat","en"],
	"al puente":["bridge","es"], "ve al puente":["bridge","es"],
	"to bridge":["bridge","en"], "to the bridge":["bridge","en"], "go to the bridge":["bridge","en"],
	"detras del bote":["behind_boat","es"], "ve detras del bote":["behind_boat","es"],
	"behind boat":["behind_boat","en"], "behind the boat":["behind_boat","en"], "go behind the boat":["behind_boat","en"],
	"ahora":["now","es"], "ahora mismo":["now","es"], "now":["now","en"], "right now":["now","en"],
	"salta":["jump","es"], "jump":["jump","en"],
	"ahora salta":["jump","es"], "now jump":["jump","en"],
}

static func normalize(text: String) -> String:
	var value := text.to_lower().strip_edges()
	for pair in [["á","a"],["é","e"],["í","i"],["ó","o"],["ú","u"],["ü","u"]]:
		value = value.replace(pair[0], pair[1])
	var clean := ""
	for character in value:
		clean += character if character in "abcdefghijklmnopqrstuvwxyzñ " else " "
	return " ".join(clean.split(" ", false))

static func match_phrase(text: String) -> Dictionary:
	var value := normalize(text)
	# Accept polite framing; preserve all other words, including negation.
	for phrase in ["por favor", "please", "xochi"]:
		value = (" " + value + " ").replace(" " + phrase + " ", " ").strip_edges()
	value = " ".join(value.split(" ", false))
	if not ALIASES.has(value):
		return {}
	var match_data: Array = ALIASES[value]
	return {"intent":match_data[0], "language":match_data[1], "phrase":value}

static func spanish_for(intent: String) -> String:
	for lesson in LESSONS:
		if lesson.intent == intent:
			return lesson.spanish
	return ""
