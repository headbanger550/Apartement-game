extends Node3D

var weapon_num_max : int
var weapon_num = 0

var children : Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	children = get_children()
	weapon_num_max = children.size()
	check_weapons()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("scroll_up"):
		weapon_num += 1
		if weapon_num > weapon_num_max:
			weapon_num = 1
		check_weapons()
	if Input.is_action_just_pressed("scroll_down"):
		weapon_num -= 1
		if weapon_num < 1:
			weapon_num = weapon_num_max
		check_weapons()

func check_weapons():
	for i in children:
		if i == children[weapon_num - 1]:
			i.can_shoot = true
			i.show()
		else:
			i.can_shoot = false
			i.hide()
