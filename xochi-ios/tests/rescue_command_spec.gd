extends "res://tests/rescue_route_spec.gd"
func tap(id: String) -> void:
	if id.begins_with("Action_"):
		var commands := {"Action_come":"ven", "Action_distract":"look over there", "Action_wait":"espera"}
		game.voice.submit_text(commands[id])
		await ticks(8)
	else: await super.tap(id)
