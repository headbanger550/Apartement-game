extends Node3D

var interactables : Array

var switched = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactables = get_children()
	for i in interactables:
			match i.resource.id:
				0:
					i.hide()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func switch_interactables():
	if !switched:
		for i in interactables:
			match i.resource.id:
				0:
					i.show()
		switched = true
	else:
		for i in interactables:
			match i.resource.id:
				0:
					i.hide()
		switched = false


func _on_static_body_3d_switch_switched() -> void:
	switch_interactables()
