extends Node

@export var receiver_path: NodePath
@export var label_path: NodePath
@export var debug_print := false

var receiver: Node
var label_node: Label

var last_left := ""
var last_right := ""

# Indices MediaPipe
const WRIST := 0

const THUMB_TIP := 4
const THUMB_MCP := 2

const INDEX_TIP := 8
const INDEX_MCP := 5

const MIDDLE_TIP := 12
const MIDDLE_MCP := 9

const RING_TIP := 16
const RING_MCP := 13

const PINKY_TIP := 20
const PINKY_MCP := 17

func _ready():
	receiver = get_node(receiver_path) if receiver_path != NodePath() else get_parent().get_node("HandUDPReceiver")
	label_node = get_node(label_path) if label_path != NodePath() else null

func _process(_dt):
	if receiver == null:
		return

	var latest: Dictionary = receiver.latest
	if latest.is_empty():
		_set_label("Gesture: (no data)")
		return

	var hands_arr: Array = latest.get("hands", [])
	if hands_arr.is_empty():
		_set_label("Gesture: (no hands)")
		return

	var left_hand := _find_hand(hands_arr, "Left")
	var right_hand := _find_hand(hands_arr, "Right")

	var left_g := ""
	var right_g := ""

	if not left_hand.is_empty():
		left_g = detect_gesture(left_hand.get("landmarks", []), "Left")
	if not right_hand.is_empty():
		right_g = detect_gesture(right_hand.get("landmarks", []), "Right")

	# Si solo hay una mano, mostramos igual
	if left_g != last_left or right_g != last_right:
		last_left = left_g
		last_right = right_g
		if debug_print:
			print("Left:", left_g, "Right:", right_g)

	var text := "Left: %s | Right: %s" % [_pretty(left_g), _pretty(right_g)]
	_set_label("Gesture: " + text)

func _set_label(t: String):
	if label_node != null:
		label_node.text = t

func _pretty(g: String) -> String:
	return g if g != "" else "-"

func _find_hand(hands_arr: Array, label: String) -> Dictionary:
	for h in hands_arr:
		if h.get("label", "") == label:
			return h
	return {}

func detect_gesture(lms: Array, hand_label: String) -> String:
	if lms.size() != 21:
		return ""

	var thumb_ext := _finger_extended(lms, THUMB_TIP, THUMB_MCP, 0.08)
	var idx_ext := _finger_extended(lms, INDEX_TIP, INDEX_MCP, 0.12)
	var mid_ext := _finger_extended(lms, MIDDLE_TIP, MIDDLE_MCP, 0.12)
	var ring_ext := _finger_extended(lms, RING_TIP, RING_MCP, 0.12)
	var pink_ext := _finger_extended(lms, PINKY_TIP, PINKY_MCP, 0.12)

	# pulgar arriba/abajo (en mediapipe, y hacia abajo)
	var thumb_up := _y(lms, THUMB_TIP) < _y(lms, WRIST) - 0.03
	var thumb_down := _y(lms, THUMB_TIP) > _y(lms, WRIST) + 0.03

	var together := _fingers_together(lms)      # puntas cerca entre sí
	var separated := _fingers_separated(lms)    # puntas más separadas

	# ---- Gestos base
	# CERRADA: nada extendido
	if (not thumb_ext) and (not idx_ext) and (not mid_ext) and (not ring_ext) and (not pink_ext):
		return "CERRADA"

	# BIEN / MAL: puño + pulgar
	if (not idx_ext) and (not mid_ext) and (not ring_ext) and (not pink_ext) and thumb_ext and thumb_up:
		return "BIEN"
	if (not idx_ext) and (not mid_ext) and (not ring_ext) and (not pink_ext) and thumb_ext and thumb_down:
		return "MAL"

	# ---- Números
	# UNO: solo índice
	if idx_ext and (not mid_ext) and (not ring_ext) and (not pink_ext) and (not thumb_ext):
		return "UNO"

	# DOS: índice + medio
	if idx_ext and mid_ext and (not ring_ext) and (not pink_ext) and (not thumb_ext):
		return "DOS"

	# TRES: índice + medio + pulgar (como pediste)
	if idx_ext and mid_ext and (not ring_ext) and (not pink_ext) and thumb_ext and thumb_up:
		return "TRES"

	# CUATRO: todos menos pulgar
	if idx_ext and mid_ext and ring_ext and pink_ext and (not thumb_ext):
		return "CUATRO"

	# CINCO: todos extendidos y separados
	if thumb_ext and idx_ext and mid_ext and ring_ext and pink_ext and separated:
		return "CINCO"

	# ABIERTA: todos extendidos y juntos
	if thumb_ext and idx_ext and mid_ext and ring_ext and pink_ext and together:
		return "ABIERTA"

	return "OTRO"

func _finger_extended(lms: Array, tip: int, mcp: int, margin := 0.12) -> bool:
	var d_tip := _dist(lms, WRIST, tip)
	var d_mcp := _dist(lms, WRIST, mcp)
	return d_tip > d_mcp + margin

func _fingers_together(lms: Array) -> bool:
	# Chequeo simple de “juntos” usando spread en X entre puntas
	var x8 = _x(lms, INDEX_TIP)
	var x12 = _x(lms, MIDDLE_TIP)
	var x16 = _x(lms, RING_TIP)
	var x20 = _x(lms, PINKY_TIP)

	var spread = max(max(abs(x8 - x12), abs(x12 - x16)), abs(x16 - x20))
	return spread < 0.10

func _fingers_separated(lms: Array) -> bool:
	# “separados”: spread mayor (ajustable)
	var x8 = _x(lms, INDEX_TIP)
	var x12 = _x(lms, MIDDLE_TIP)
	var x16 = _x(lms, RING_TIP)
	var x20 = _x(lms, PINKY_TIP)

	var spread = max(max(abs(x8 - x12), abs(x12 - x16)), abs(x16 - x20))
	return spread > 0.16

func _x(lms: Array, i: int) -> float:
	return float(lms[i][0])

func _y(lms: Array, i: int) -> float:
	return float(lms[i][1])

func _z(lms: Array, i: int) -> float:
	return float(lms[i][2])

func _dist(lms: Array, a: int, b: int) -> float:
	var ax = _x(lms, a)
	var ay = _y(lms, a)
	var az = _z(lms, a)
	var bx = _x(lms, b)
	var by = _y(lms, b)
	var bz = _z(lms, b)
	return sqrt((ax-bx)*(ax-bx) + (ay-by)*(ay-by) + (az-bz)*(az-bz))
