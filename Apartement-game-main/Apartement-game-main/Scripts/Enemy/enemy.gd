extends CharacterBody3D

@export var speed : float
@export var health : float
@export var aggresion : float

@export var enemy_distance : float
var distance_to_player : float

@export var patrol_points : Array[Node3D]

var active = false
var chosen_point = false
var attacked = false

@onready var nav = $NavigationAgent3D
@onready var wait_timer = $"Wait timer"
@onready var attack_timer = $"Attack timer"
@onready var eyes_ray = $"E Y E S"

var player : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node("../Player")
	
	wait_timer.wait_time = clampf(wait_timer.wait_time, 0.0, wait_timer.wait_time)
	wait_timer.wait_time /= aggresion
	#attack_timer.wait_time = clampf(attack_timer.wait_time, 0.0, attack_timer.wait_time)
	attack_timer.wait_time /= aggresion
	speed *= aggresion


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	distance_to_player = global_position.distance_to(player.global_position)
	
	var player_direction = global_position.direction_to(player.global_position)
	if player_direction.dot(global_transform.basis.z) > 0 and !active:
		eyes_ray.look_at(player.global_position)
		if eyes_ray.is_colliding():
			if eyes_ray.get_collider().is_in_group("player"):
				print("saw ya :p")
				active = true
	
	if eyes_ray.is_colliding():
		#print(eyes_ray.get_collider())
		pass
	
	if health <= 0:
		print("dead")
		queue_free()
	
	patrol()
	var current_pos = global_transform.origin
	var next_pos = nav.get_next_path_position()
	var new_velocity = (next_pos - current_pos).normalized() * speed
	
	nav.set_velocity(new_velocity)
	
	look_at(nav.target_position)
	rotation_degrees.x = 0.0
	
	if attacked:
		attack_timer.start()
	
func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_navigation_agent_3d_target_reached() -> void:
	if !active:
		wait_timer.start()
	else:
		if !attacked:
			print("lol lmao")
			attacked = true
	
func damage_enemy(damage : float):
	print("lol")
	health -= damage
	
func patrol():
	if !active:
		if !chosen_point:
			var random_point = randi_range(0, patrol_points.size() - 1)
			nav.set_target_position(patrol_points[random_point].global_position)
			chosen_point = true
	else:
		nav.set_target_position(player.global_transform.origin)

func react_to_sound(new_target):
	print("heard ya loud and clear")
	nav.set_target_position(new_target)

func _on_wait_timer_timeout() -> void:
	chosen_point = false


func _on_attack_timer_timeout() -> void:
	attacked = false
	print("can attack")
