extends Node3D

@onready var spawn_pos = $"../Head/Camera3D/object_pos"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func make_removed_item(item_base):
	var new_item = RigidBody3D.new()
	new_item.sleeping = true
	new_item.name = item_base.name
	new_item.add_to_group("item")
	get_tree().root.add_child(new_item)
	
	var collider = CollisionShape3D.new()
	collider.shape = SphereShape3D.new()
	new_item.add_child(collider)
	
	var mesh = MeshInstance3D.new()
	mesh.mesh = item_base.model
	new_item.add_child(mesh)
	
	new_item.set_script(load("res://Scripts/Items/item.gd"))
	new_item.item = item_base
	
	new_item.global_position = spawn_pos.global_position
