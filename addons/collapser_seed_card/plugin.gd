@tool
extends EditorPlugin

## Collapser Seed Card — an editor client of the Collapser public demo.
##
## What it does, exactly: the dock lists the two published example
## records the demo serves (fetched from GET /examples, so the words
## are the service's own), runs one against POST /demo/run, shows the
## fingerprints the service returned, and copies the run's seed card
## to the clipboard — the same card the web playground issues: the
## seed that reproduces the run, the world it made, and the result
## fingerprint.
##
## What it does not do: it derives nothing locally, holds no API key,
## and sends nothing but the example choice ('chronicle' or
## 'replay-verify'). The demo's inputs are fixed by the service; a
## seed card is something a run gives you, never something the demo
## takes in. Pilots run their own records under their own key in
## their own integration — not through this dock.

const DEMO_BASE := "https://collapser-pilot.fly.dev"
const DOMAINS: Array[String] = ["chronicle", "replay-verify"]

var _dock: VBoxContainer
var _picker: OptionButton
var _run_button: Button
var _status: Label
var _output: TextEdit
var _copy_button: Button
var _http_examples: HTTPRequest
var _http_run: HTTPRequest
var _examples: Dictionary = {}
var _last_card: String = ""


func _enter_tree() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "Collapser Seed Card"
	_dock.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "Collapser — Seed Card"
	title.add_theme_font_size_override("font_size", 15)
	_dock.add_child(title)

	var about := Label.new()
	about.text = "A client of the Collapser public demo. It runs the two published example records against the live demo service and copies the run's seed card. It derives nothing locally and takes no key."
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_BOUNDARY
	_dock.add_child(about)

	_picker = OptionButton.new()
	_picker.add_item("Loading the published examples…", 0)
	_picker.disabled = true
	_dock.add_child(_picker)

	_run_button = Button.new()
	_run_button.text = "Run the demo"
	_run_button.disabled = true
	_run_button.pressed.connect(_on_run_pressed)
	_dock.add_child(_run_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_BOUNDARY
	_dock.add_child(_status)

	_output = TextEdit.new()
	_output.editable = false
	_output.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_output.custom_minimum_size = Vector2(0, 190)
	_output.placeholder_text = "The run's fingerprints and its seed card will appear here."
	_dock.add_child(_output)

	_copy_button = Button.new()
	_copy_button.text = "Copy the seed card"
	_copy_button.disabled = true
	_copy_button.pressed.connect(_on_copy_pressed)
	_dock.add_child(_copy_button)

	var open_button := Button.new()
	open_button.text = "Open the playground in a browser"
	open_button.pressed.connect(func() -> void: OS.shell_open(DEMO_BASE + "/"))
	_dock.add_child(open_button)

	_http_examples = HTTPRequest.new()
	_dock.add_child(_http_examples)
	_http_examples.request_completed.connect(_on_examples_completed)
	_http_run = HTTPRequest.new()
	_dock.add_child(_http_run)
	_http_run.request_completed.connect(_on_run_completed)

	add_control_to_dock(DOCK_SLOT_RIGHT_UR, _dock)
	_fetch_examples()


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	_dock.queue_free()


func _fetch_examples() -> void:
	var err := _http_examples.request(DEMO_BASE + "/examples")
	if err != OK:
		_status.text = "The examples could not be requested (error %d). The dock names the two published examples; running still works." % err
		_fill_picker_fallback()


func _on_examples_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_status.text = "The demo service did not answer the examples request (HTTP %d). Running still works — the dock falls back to the examples' names." % response_code
		_fill_picker_fallback()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("examples"):
		_status.text = "The examples response was not the published shape. Running still works with the fallback names."
		_fill_picker_fallback()
		return
	_examples = parsed["examples"]
	_picker.clear()
	for domain in DOMAINS:
		if _examples.has(domain):
			_picker.add_item(_world_title(domain, _examples[domain]))
			_picker.set_item_metadata(_picker.item_count - 1, domain)
	_picker.disabled = false
	_run_button.disabled = false
	_status.text = "The published examples, in the service's own words. Pick one and run it."


func _fill_picker_fallback() -> void:
	# The examples' identities as published; if the fetch failed, the
	# run still names its domain and the card is built from the run
	# response alone.
	_examples = {
		"chronicle": {"subject": "mara-voss", "founding": {"hero": "Mara Voss", "calling": "the Tide Bell", "home": "Kettle Harbour", "motif": "brass"}, "collapses": []},
		"replay-verify": {"subject": "neon-harvest-grand-final", "founding": {"game": "Neon Harvest", "ruleset": "duel-rules@1", "seed": 20260814}, "collapses": [{"pin": "verify-score@1", "params": {"claimedScore": 16}}]},
	}
	_picker.clear()
	for domain in DOMAINS:
		_picker.add_item(_world_title(domain, _examples[domain]))
		_picker.set_item_metadata(_picker.item_count - 1, domain)
	_picker.disabled = false
	_run_button.disabled = false


func _selected_domain() -> String:
	if _picker.item_count == 0:
		return "chronicle"
	var meta: Variant = _picker.get_item_metadata(_picker.selected)
	return str(meta) if meta != null else "chronicle"


func _world_title(domain: String, ex: Dictionary) -> String:
	var founding: Dictionary = ex.get("founding", {})
	if domain == "chronicle":
		return "%s and %s" % [str(founding.get("hero", "")), str(founding.get("calling", ""))]
	return "%s — the grand final" % str(founding.get("game", ""))


func _world_line(domain: String, ex: Dictionary) -> String:
	var founding: Dictionary = ex.get("founding", {})
	if domain == "chronicle":
		return "%s · %s · of %s · motif %s" % [str(founding.get("hero", "")), str(founding.get("calling", "")), str(founding.get("home", "")), str(founding.get("motif", ""))]
	return "%s · %s · founding seed %s" % [str(founding.get("game", "")), str(founding.get("ruleset", "")), str(founding.get("seed", ""))]


func _seed_token(ex: Dictionary) -> String:
	var founding: Dictionary = ex.get("founding", {})
	if founding.has("seed"):
		return str(founding["seed"])
	return str(ex.get("subject", ""))


func _on_run_pressed() -> void:
	var domain := _selected_domain()
	_run_button.disabled = true
	_copy_button.disabled = true
	_status.text = "Running the published example against the live demo…"
	var body := JSON.stringify({"domain": domain})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http_run.request(DEMO_BASE + "/demo/run", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_run_button.disabled = false
		_status.text = "The run could not be requested (error %d)." % err


func _on_run_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_run_button.disabled = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_status.text = "The demo did not complete the run (HTTP %d). Nothing was derived for this press." % response_code
		return
	var run: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(run) != TYPE_DICTIONARY or not run.has("collapses"):
		_status.text = "The run response was not the demo's transcript shape."
		return
	var domain := _selected_domain()
	var ex: Dictionary = _examples.get(domain, {})
	_last_card = _card_text(domain, ex, run)
	_output.text = _last_card
	_copy_button.disabled = false
	_status.text = "The run stands. Its seed card is below — copy it, and whoever runs the same seed can check the fingerprint."


func _card_text(domain: String, ex: Dictionary, run: Dictionary) -> String:
	var collapses: Array = run.get("collapses", [])
	var first: Dictionary = collapses[0] if collapses.size() > 0 else {}
	var verify: Dictionary = run.get("verify", {})
	var replay: Dictionary = run.get("replay", {})
	var token := _seed_token(ex)
	var hex := str(first.get("outputHash", "")).trim_prefix("sha256:")
	var lines: Array[String] = []
	lines.append("THE COLLAPSER — SEED CARD")
	lines.append("World: " + _world_title(domain, ex))
	lines.append(_world_line(domain, ex))
	lines.append("Seed: " + token)
	lines.append("Result fingerprint: " + str(first.get("outputHash", "")))
	lines.append("Record fingerprint: " + str(run.get("recordHash", "")))
	if domain == "replay-verify":
		var specs: Array = ex.get("collapses", [])
		if specs.size() > 0:
			var params: Dictionary = specs[0].get("params", {})
			if params.has("claimedScore"):
				lines.append("The score the record folds to: " + str(params["claimedScore"]))
	lines.append("Self-check: %s — re-derived from the record by the verifier" % str(verify.get("verdict", "")))
	lines.append("Whole-record replay: every step MATCH" if bool(replay.get("allMatch", false)) else "Whole-record replay: did not fully match — see the raw transcript in the playground")
	lines.append("Run this seed yourself: %s/?seed=%s&h=%s" % [DEMO_BASE, token.uri_encode(), hex.substr(0, 12)])
	lines.append("Same seed, same world — the fingerprint must come back identical.")
	return "\n".join(lines)


func _on_copy_pressed() -> void:
	if _last_card.is_empty():
		return
	DisplayServer.clipboard_set(_last_card)
	_status.text = "The seed card is on the clipboard: seed, world, and fingerprint, as plain text."
