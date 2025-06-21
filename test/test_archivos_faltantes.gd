extends GutTest
#
# Tests unitarios para:
#   • scripts/game_over_menu.gd
#   • scripts/hud.gd
#   • scripts/pause_menu.gd
# Un único archivo con 11 pruebas.
#

# ─────────────────────────────
#  Rutas a los scripts reales
# ─────────────────────────────
const GAME_OVER_MENU := preload("res://scripts/game_over_menu.gd")
const HUD            := preload("res://scripts/hud.gd")
const PAUSE_MENU     := preload("res://scripts/pause_menu.gd")

# ─────────────────────────────
#  Flag y callback genéricos
# ─────────────────────────────
var _sig := false
func _flag() -> void: _sig = true     # receptor genérico de señales

# ─────────────────────────────
#  Utilidades para nodos dummy
# ─────────────────────────────
func _lbl(name: String) -> Label:
	var n := Label.new(); n.name = name; return n

func _btn(name: String) -> Button:
	var n := Button.new(); n.name = name; return n

func _bar(name: String) -> ProgressBar:
	var n := ProgressBar.new(); n.name = name; return n

# ════════════════════════════════════════════════════════════════
#  Helpers de instanciación de cada panel
# ════════════════════════════════════════════════════════════════
func _gomenu() -> CanvasLayer:
	var m := CanvasLayer.new()
	m.set_script(GAME_OVER_MENU)
	m.add_child(_lbl("FinalScoreLabel"))
	return m

func _hud() -> CanvasLayer:
	var h := CanvasLayer.new()
	h.set_script(HUD)
	h.add_child(_lbl("ScoreLabel"))
	h.add_child(_bar("HealthBar"))

	var start: Button = _btn("StartButton")
	h.add_child(start)

	var hl := Control.new(); hl.name = "HealthLabel"
	hl.add_child(_lbl("VIDITA"))
	h.add_child(hl)
	return h

func _pause() -> CanvasLayer:
	var p := CanvasLayer.new()
	p.set_script(PAUSE_MENU)
	return p


# ════════════════════════════════════════════════════════════════
#  TESTS – GAME OVER MENU
# ════════════════════════════════════════════════════════════════

# TEST 1 – Comprueba que update_final_score() actualiza el texto del label.
func test_gomenu_actualiza_score() -> void:
	var menu := _gomenu()
	add_child_autofree(menu)
	menu.update_final_score(42)
	assert_eq(menu.get_node("FinalScoreLabel").text, "Your Score: 42")


# TEST 2 – Verifica que al pulsar Restart se emite la señal restart.
func test_gomenu_emite_restart() -> void:
	var menu := _gomenu()
	add_child_autofree(menu)
	_sig = false
	menu.connect("restart", Callable(self, "_flag"))
	menu._on_restart_button_pressed()
	assert_true(_sig)


# TEST 3 – Verifica que al pulsar Exit se emite la señal exit.
func test_gomenu_emite_exit() -> void:
	var menu := _gomenu()
	add_child_autofree(menu)
	_sig = false
	menu.connect("exit", Callable(self, "_flag"))
	menu._on_exit_button_pressed()
	assert_true(_sig)


# ════════════════════════════════════════════════════════════════
#  TESTS – HUD
# ════════════════════════════════════════════════════════════════

# TEST 4 – update_score() debe plasmar el valor en el ScoreLabel.
func test_hud_update_score() -> void:
	var hud := _hud()
	add_child_autofree(hud)
	hud.update_score(7)
	assert_eq(hud.get_node("ScoreLabel").text, "Score: 7")


# TEST 5 – update_health() debe actualizar el valor del ProgressBar.
func test_hud_update_health() -> void:
	var hud := _hud()
	add_child_autofree(hud)
	hud.update_health(55)
	assert_eq(hud.get_node("HealthBar").value, 55)


# TEST 6 – Al pulsar Start se emite la señal start_game.
func test_hud_emite_start_game() -> void:
	var hud := _hud()
	add_child_autofree(hud)
	_sig = false
	hud.connect("start_game", Callable(self, "_flag"))
	hud._on_start_button_pressed()
	assert_true(_sig)


# TEST 7 – El botón Start se oculta tras pulsarlo.
func test_hud_start_button_hide() -> void:
	var hud := _hud()
	add_child_autofree(hud)
	hud._on_start_button_pressed()
	assert_false(hud.get_node("StartButton").visible)


# TEST 8 – El label VIDITA se oculta tras pulsar Start.
func test_hud_vidita_hide() -> void:
	var hud := _hud()
	add_child_autofree(hud)
	hud._on_start_button_pressed()
	assert_false(hud.get_node("HealthLabel/VIDITA").visible)


# ════════════════════════════════════════════════════════════════
#  TESTS – PAUSE MENU
# ════════════════════════════════════════════════════════════════

# TEST 9 – Al pulsar Resume se emite la señal resume.
func test_pause_resume_signal() -> void:
	var menu := _pause()
	add_child_autofree(menu)
	_sig = false
	menu.connect("resume", Callable(self, "_flag"))
	menu._on_resume_button_pressed()
	assert_true(_sig)


# TEST 10 – Al pulsar Exit se emite la señal exit.
func test_pause_exit_signal() -> void:
	var menu := _pause()
	add_child_autofree(menu)
	_sig = false
	menu.connect("exit", Callable(self, "_flag"))
	menu._on_exit_button_pressed()
	assert_true(_sig)


# TEST 11 – Los tres scripts deben heredar de CanvasLayer.
func test_scripts_son_canvaslayer() -> void:
	assert_true(GAME_OVER_MENU.new() is CanvasLayer)
	assert_true(HUD.new()            is CanvasLayer)
	assert_true(PAUSE_MENU.new()     is CanvasLayer)
