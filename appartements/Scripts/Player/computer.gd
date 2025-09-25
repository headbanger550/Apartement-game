extends Node3D

@onready var sub_viewport = $Screen/SubViewport
@onready var cam_pos = $"Camera position"
@onready var text_edit = $Screen/SubViewport/Control/TextEdit

var current_line = 0

var interacting = false

func _input(event: InputEvent) -> void:
	if interacting:
		sub_viewport.push_input(event)
	if Input.is_action_just_pressed("new_line"):
		var got_line = text_edit.get_line(current_line)
		var line_array = got_line.split(" ", true)
		for line in line_array.size() - 1:
			if line_array[line] == "ping":
				if line_array[line + 1] == "area":
					print("pinged area")
		current_line += 1
		#text_edit.set_line(current_line, "[luna@Laptop ~]$ ")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_edit.set_line(current_line, "[luna@Laptop ~]$ ")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_text_edit_gui_input(event: InputEvent) -> void:
	pass
