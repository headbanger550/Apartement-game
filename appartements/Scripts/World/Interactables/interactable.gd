extends Node3D

@export var resource : Resource

func _ready() -> void:
	name = resource.name
