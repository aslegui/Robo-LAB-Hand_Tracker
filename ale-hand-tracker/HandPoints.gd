extends Node3D

@export var tracker_path: NodePath
@export var scale_xy := 0.6
@export var scale_z := 0.6
@export var smooth := 0.35
@export var point_radius := 0.015
@export var debug_print := false

var tracker: Node
var left_points: Array[MeshInstance3D] = []
var right_points: Array[MeshInstance3D] = []
var left_pos: Array[Vector3] = []
var right_pos: Array[Vector3] = []

func _ready():
	if tracker_path == NodePath():
		tracker = get_parent().get_node("HandUDPReceiver")
	else:
		tracker = get_node(tracker_path)

	left_points = _make_points("L_")
	right_points = _make_points("R_")

	left_pos.resize(21)
	right_pos.resize(21)
	for i in range(21):
		left_pos[i] = Vector3.ZERO
		right_pos[i] = Vector3.ZERO

func _make_points(prefix: String) -> Array[MeshInstance3D]:
	var arr: Array[MeshInstance3D] = []

	var sphere := SphereMesh.new()
	sphere.radius = point_radius
	sphere.height = point_radius * 2.0

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in range(21):
		var mi := MeshInstance3D.new()
		mi.name = "%s%d" % [prefix, i]
		mi.mesh = sphere
		mi.material_override = mat
		mi.visible = false
		add_child(mi)
		arr.append(mi)

	return arr

func _process(_dt):
	if tracker == null:
		return

	var latest: Dictionary = tracker.latest
	if latest.is_empty():
		_set_visible(false, left_points)
		_set_visible(false, right_points)
		return

	_set_visible(false, left_points)
	_set_visible(false, right_points)

	var hands_arr: Array = latest.get("hands", [])
	if debug_print:
		print("hands received:", hands_arr.size())

	for h in hands_arr:
		var label: String = h.get("label", "")
		var lms: Array = h.get("landmarks", [])
		if lms.size() != 21:
			continue

		var points = left_points if label == "Left" else right_points
		var poses = left_pos if label == "Left" else right_pos

		for i in range(21):
			var lm = lms[i]
			var x = float(lm[0]) - 0.5
			var y = float(lm[1]) - 0.5
			var z = float(lm[2])

			var target = Vector3(
				x * scale_xy,
				-y * scale_xy,
				-z * scale_z
			)

			poses[i] = poses[i].lerp(target, smooth)
			points[i].position = poses[i]
			points[i].visible = true

func _set_visible(v: bool, arr: Array):
	for n in arr:
		n.visible = v
