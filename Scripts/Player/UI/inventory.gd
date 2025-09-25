extends Control

#var slot_num : int
var slots : Array

var added_item = false

@onready var parent = $"../.."
var manager : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slots = get_children()
	manager = parent.get_parent()
	for i in slots:
		i.on_item_remove.connect(remove_item)
	#print(slots)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_item(item):
	added_item = false
	for x in slots:
		if !x.has_item and !added_item:
			x.id = item.item.id
			x.item_image = item.item.image
			x.item_base = item.item
			x.add_item_to_container()
			added_item = true
			
func remove_item(item_base):
	manager.make_removed_item(item_base)
