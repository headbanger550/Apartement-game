extends Node3D

@onready var ray = $"../../RayCast3D"

var can_shoot = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_shoot:
		if ray.is_colliding():
			if ray.get_collider().is_in_group("enemy"):
				var got_enemy = ray.get_collider()
				print(got_enemy.frequency)
