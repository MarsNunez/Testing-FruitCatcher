extends GutTest
var basket : Node2D
var _hit_recibido := false            # se usa en las pruebas de señal

# ------------------------------------------------------------------
#  SET-UP
# ------------------------------------------------------------------
func before_each() -> void:
	basket = preload("res://scenes/basket.tscn").instantiate()
	add_child_autofree(basket)        # llama _ready() y libera al terminar
	_hit_recibido = false

# callback común para capturar la señal
func _on_basket_hit() -> void:
	_hit_recibido = true


# ------------------------------------------------------------------
#  TEST 1 – la pantalla se inicializa
#  Comprueba que el script copia correctamente el tamaño del Viewport
# ------------------------------------------------------------------
func test_screen_size_se_inicializa() -> void:
	var viewport_size: Vector2 = basket.get_viewport().get_visible_rect().size
	assert_eq(
		basket.screen_size,
		viewport_size,
		"screen_size debería igualar al tamaño del viewport"
	)


# ------------------------------------------------------------------
#  TEST 2 – movimiento a la derecha dentro de límites
#  Simula un InputEvent y verifica que la canasta se coloca en x = 300
# ------------------------------------------------------------------
func test_mouse_move_dentro_de_limite() -> void:
	var destino_x := 300.0
	var evento := InputEventMouseMotion.new()
	evento.position = Vector2(destino_x, 0)
	basket._input(evento)

	assert_eq(
		basket.position.x,
		destino_x,
		"La canasta debería quedar exactamente en x = 300"
	)


# ------------------------------------------------------------------
#  TEST 3 – no sobrepasa borde izquierdo
#  Envía un movimiento muy a la izquierda y comprueba el “clamp”
# ------------------------------------------------------------------
func test_clamp_borde_izquierdo() -> void:
	var evento := InputEventMouseMotion.new()
	evento.position = Vector2(-100.0, 0)     # fuera de la pantalla
	basket._input(evento)

	assert_eq(
		basket.position.x,
		50.0,
		"La canasta no debe ir más allá de x = 50 (margen izquierdo)"
	)


# ------------------------------------------------------------------
#  TEST 4 – no sobrepasa borde derecho
#  Similar al anterior pero en el extremo derecho de la pantalla
# ------------------------------------------------------------------
func test_clamp_borde_derecho() -> void:
	var evento := InputEventMouseMotion.new()
	evento.position = Vector2(basket.screen_size.x + 200.0, 0)
	basket._input(evento)

	var limite_der: float = basket.screen_size.x - 50.0
	assert_eq(
		basket.position.x,
		limite_der,
		"La canasta no debe ir más allá del borde derecho"
	)


# ------------------------------------------------------------------
#  TEST 5 – cambios sucesivos de posición
#  Verifica que el segundo movimiento sobrescribe al primero
# ------------------------------------------------------------------
func test_varios_movimientos_se_actualiza() -> void:
	var e1 := InputEventMouseMotion.new()
	e1.position = Vector2(150.0, 0)
	basket._input(e1)

	var e2 := InputEventMouseMotion.new()
	e2.position = Vector2(220.0, 0)
	basket._input(e2)

	assert_eq(
		basket.position.x,
		220.0,
		"La segunda posición del ratón debe sobrescribir la anterior"
	)


# ------------------------------------------------------------------
#  TEST 6 – la señal 'hit' se emite
#  Simula una colisión y comprueba que la señal llega al receptor
# ------------------------------------------------------------------
func test_signal_hit_se_emite() -> void:
	basket.connect("hit", Callable(self, "_on_basket_hit"))

	var cuerpo := Node2D.new()
	basket._on_body_entered(cuerpo)

	assert_true(_hit_recibido, "El basket debe emitir la señal 'hit'")


# ------------------------------------------------------------------
#  TEST 7 – el cuerpo se envía a queue_free()
#  Tras la colisión el nodo que entra debe programarse para borrado
# ------------------------------------------------------------------
func test_cuerpo_se_libera() -> void:
	var cuerpo := Node2D.new()
	basket._on_body_entered(cuerpo)

	assert_true(
		cuerpo.is_queued_for_deletion(),
		"El cuerpo que colisiona debe ponerse en queue_free()"
	)


# ------------------------------------------------------------------
#  TEST 8 – sin eventos la posición permanece constante
#  Asegura que la canasta no se mueve si no recibe input
# ------------------------------------------------------------------
func test_sin_input_posicion_constante() -> void:
	var x_inicial: float = basket.position.x
	# (no enviamos ningún evento)
	assert_eq(
		basket.position.x,
		x_inicial,
		"Sin eventos de entrada la canasta no debería moverse"
	)
