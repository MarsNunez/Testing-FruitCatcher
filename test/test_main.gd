extends GutTest

# ------------------------------------------------------------------
#  ──  STUBS / DOBLES  ──
# ------------------------------------------------------------------
class HUDStub:
	extends Node
	var last_score  : int = -1
	var last_health : int = -1
	func update_score(s):  last_score  = s
	func update_health(h): last_health = h

class GameOverMenuStub:
	extends Control
	var last_final_score := -1
	func update_final_score(s): last_final_score = s

class FruitStub:
	extends Node2D
	signal fruit_missed


# ------------------------------------------------------------------
#  SET-UP
# ------------------------------------------------------------------
const MAIN_SCRIPT := preload("res://scripts/main.gd")   # ajusta la ruta si cambia
var main : Node

func before_each() -> void:
	# ── nos aseguramos de que la acción “toggle_pause” exista ──
	if not InputMap.has_action("toggle_pause"):
		InputMap.add_action("toggle_pause")

	# ── instanciamos un Node vacío y le asignamos el script Main ──
	main = Node.new()
	main.set_script(MAIN_SCRIPT)

	# ── hijos que Main espera ──
	var pause_menu := Control.new()
	pause_menu.name = "PauseMenu"
	main.add_child(pause_menu)

	var game_over_menu := GameOverMenuStub.new()
	game_over_menu.name = "GameOverMenu"
	main.add_child(game_over_menu)

	var hud := HUDStub.new()
	hud.name = "HUD"
	main.add_child(hud)

	var timer := Timer.new()
	timer.name = "FruitTimer"
	main.add_child(timer)

	# ── creamos un PackedScene-stub que devuelve FruitStub ──
	var fruit_scene_stub := PackedScene.new()
	var prototype := FruitStub.new()
	prototype.name = "FruitStub"
	prototype.add_to_group("fruits", true)   # ← persistente en la escena
	fruit_scene_stub.pack(prototype)

	main.fruit_scene = fruit_scene_stub

	# ── añadimos Main al árbol para que se ejecute _ready() ──
	add_child_autofree(main)


# ------------------------------------------------------------------
#  TEST 1 – _ready pausa el juego y oculta los menús
# ------------------------------------------------------------------
func test_ready_oculta_menus_y_pausa() -> void:
	assert_true(get_tree().paused)
	assert_false(main.get_node("PauseMenu").visible)
	assert_false(main.get_node("GameOverMenu").visible)


# ------------------------------------------------------------------
#  TEST 2 – new_game reinicia variables y reanuda el juego
# ------------------------------------------------------------------
func test_new_game_resetea_estado() -> void:
	main.new_game()

	assert_false(get_tree().paused)
	assert_true(main.game_started)
	assert_eq(main.score, 0)
	assert_eq(main.health, 100)
	assert_eq(main.get_node("FruitTimer").wait_time, 1.0)
	assert_false(main.get_node("GameOverMenu").visible)
	assert_eq(main.get_node("HUD").last_health, 100)


# ------------------------------------------------------------------
#  TEST 3 – fruit_caught incrementa score y acelera el timer
# ------------------------------------------------------------------
func test_fruit_caught_suma_score_y_acelera() -> void:
	main.new_game()
	var timer := main.get_node("FruitTimer")
	var wait_anterior: float = timer.wait_time

	main.fruit_caught()

	assert_eq(main.score, 1)
	assert_eq(timer.wait_time, wait_anterior - 0.01)


# ------------------------------------------------------------------
#  TEST 4 – fruit_missed resta salud si aún quedan vidas
# ------------------------------------------------------------------
func test_fruit_missed_resta_salud() -> void:
	main.new_game()
	main.fruit_missed()

	assert_eq(main.health, 90)
	assert_false(get_tree().paused)
	assert_false(main.get_node("GameOverMenu").visible)


# ------------------------------------------------------------------
#  TEST 5 – fruit_missed provoca Game Over con health ≤ 0
# ------------------------------------------------------------------
func test_game_over_con_salud_cero() -> void:
	main.new_game()
	main.health = 10
	main.fruit_missed()

	var go := main.get_node("GameOverMenu")
	assert_true(get_tree().paused)
	assert_true(go.visible)
	assert_eq(go.last_final_score, main.score)
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE)


# ------------------------------------------------------------------
#  TEST 6 – pause_game pausa y muestra menú
# ------------------------------------------------------------------
func test_pause_game() -> void:
	main.new_game()
	main.pause_game()

	assert_true(get_tree().paused)
	assert_true(main.get_node("PauseMenu").visible)
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE)


# ------------------------------------------------------------------
#  TEST 7 – resume_game reanuda y oculta menú
# ------------------------------------------------------------------
func test_resume_game() -> void:
	main.new_game()
	main.pause_game()
	main.resume_game()

	assert_false(get_tree().paused)
	assert_false(main.get_node("PauseMenu").visible)
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_HIDDEN)


# ------------------------------------------------------------------
#  TEST 8 – _on_fruit_timer_timeout añade una fruta
# ------------------------------------------------------------------
func test_spawn_de_fruta() -> void:
	var hijos_antes := main.get_child_count()
	main._on_fruit_timer_timeout()

	assert_eq(main.get_child_count(), hijos_antes + 1)
	assert_true(main.get_child(hijos_antes).is_in_group("fruits"))


# ------------------------------------------------------------------
#  TEST 9 – dificultad aumenta tras varias capturas
# ------------------------------------------------------------------
func test_timer_disminuye_acumulativo() -> void:
	main.new_game()
	var timer := main.get_node("FruitTimer")

	for i in 5:
		main.fruit_caught()

	assert_eq(timer.wait_time, 1.0 - 5 * 0.01)
