extends Control

var item : Resource

var id : int
var item_image : Texture
var item_base : Resource

signal on_item_remove(base_item : Resource)

@onready var item_texture = $Item_image

var has_item = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func add_item_to_container():
	if !has_item:
		item_texture.texture = item_image
		has_item = true


func _on_button_button_down() -> void:
	has_item = false
	item_texture.texture = null
	on_item_remove.emit(item_base)
