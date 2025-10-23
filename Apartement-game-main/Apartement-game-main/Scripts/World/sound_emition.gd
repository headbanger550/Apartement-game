extends Node3D

var sound_area = preload("res://Prefabs/World/sound area.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_sound_area(size : float, duration : float, spawn_position : Vector3):
	var inst_area = sound_area.instantiate()
	get_tree().root.add_child(inst_area)
	
	var collider = inst_area.get_child(0)
	collider.scale = Vector3(1, 1, 1) * size
	
	var timer = inst_area.get_child(1)
	timer.wait_time = duration
	
	inst_area.global_position = spawn_position
