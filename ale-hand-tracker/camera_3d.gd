extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready():
	position = Vector3(0, 0, 2)
	look_at(Vector3.ZERO, Vector3.UP)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
