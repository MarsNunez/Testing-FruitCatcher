extends GutTest
var fruit            : RigidBody2D
var missed_emitido   : bool = false      # flag para la señal

const FRUIT_SCENE := preload("res://scenes/fruit.tscn")

# -------------------------------------------------------------
#  SET-UP
# -------------------------------------------------------------
func before_each() -> void:
	fruit = FRUIT_SCENE.instantiate()
	add_child_autofree(fruit)            # _ready() se ejecuta al añadirse
	missed_emitido = false

# callback para la señal
func _on_fruit_missed() -> void:
	missed_emitido = true


# -------------------------------------------------------------
#  TEST 1 – screen_size se inicializa
#  Verifica que la fruta copia el tamaño del viewport en _ready()
# -------------------------------------------------------------
func test_screen_size_se_inicializa() -> void:
	var viewport_size := fruit.get_viewport().get_visible_rect().size
	assert_eq(
		fruit.screen_size,
		viewport_size,
		"screen_size debería copiar el tamaño del viewport"
	)


# -------------------------------------------------------------
#  TEST 2 – posición X dentro del rango permitido
#  Comprueba que la coordenada x inicial respeta los márgenes
# -------------------------------------------------------------
func test_posicion_en_rango() -> void:
	var min_x  : float = 50.0
	var max_x  : float = fruit.screen_size.x - 50.0
	var x      : float = fruit.position.x

	assert_true(
		x >= min_x and x <= max_x,
		"position.x debe estar entre %s y %s (es %s)" % [min_x, max_x, x]
	)


# -------------------------------------------------------------
#  TEST 3 – velocidad angular aleatoria en [-5 … 4]
#  Garantiza que el valor asignado cae dentro del rango esperado
# -------------------------------------------------------------
func test_angular_velocity_en_rango() -> void:
	var w := fruit.angular_velocity
	assert_true(
		w >= -5 and w <= 4,
		"angular_velocity debe estar entre -5 y 4 (es %s)" % w
	)


# -------------------------------------------------------------
#  TEST 4 – emite la señal fruit_missed al salir de pantalla
#  Llama al handler y confirma la recepción de la señal
# -------------------------------------------------------------
func test_emite_senal_fruit_missed() -> void:
	fruit.connect("fruit_missed", Callable(self, "_on_fruit_missed"))

	fruit._on_visible_on_screen_notifier_2d_screen_exited()

	assert_true(
		missed_emitido,
		"Debe emitirse la señal fruit_missed cuando la fruta sale de pantalla"
	)


# -------------------------------------------------------------
#  TEST 5 – queue_free al abandonar la pantalla
#  Asegura que el nodo se marca para borrado en el mismo evento
# -------------------------------------------------------------
func test_queue_free_en_screen_exit() -> void:
	fruit._on_visible_on_screen_notifier_2d_screen_exited()

	assert_true(
		fruit.is_queued_for_deletion(),
		"La fruta debe ponerse en queue_free() cuando sale de pantalla"
	)
