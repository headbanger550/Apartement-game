extends Node3D

var muzzle_flash = preload("res://Particles/Weapon_particles/muzzle_flash.tscn")
var dust_burst = preload("res://Particles/dust_burst_1.tscn")
var impact_spark = preload("res://Particles/Weapon_particles/impact_spark.tscn")

var whole_bullet_rev = preload("res://Prefabs/Player/Weapons/Bullets/bullet_whole_rev.tscn")
var shot_bullet_rev = preload("res://Prefabs/Player/Weapons/Bullets/bullet_fired_rev.tscn")

@export var weap_res : Resource

var bullet_num : int
var bullets : Array
@export var start_bullets : int

var has_loaded = true

@export var trauma_reduction_rate = 1.0
@export var noise : FastNoiseLite
@export var noise_speed = 50.0

@export var max_x = 10.0
@export var max_y = 10.0
@export var max_z = 5.0

@export var weapon_frequency : float

@export var bullet_parent : Node3D

var trauma = 0.0
var time = 0.0

var start_pos : Vector3

var aiming = false
var reloading = false
var checking = false

var can_shoot = true

var tweened = false

@export var bullet_positions : Array[Node3D]
var current_bullet = 0
var current_bullet_rel = 0
var last_bullet_id_in_world : int

@onready var shot_point = $"Model/Shot point"
@onready var anim = $AnimationPlayer
@onready var ray = $"../../RayCast3D"
@onready var barrel_ray = $"Model/bfr revolver/Gun Frame/Barrel/Barrel_ray"
@onready var ejector_ray = $"Model/bfr revolver/Gun Frame/Barrel/Ejector handle/Ejector/RayCast3D"

@onready var cam = $"../.."
@onready var initial_rot = cam.rotation_degrees as Vector3
@onready var head = $"../../.."

@onready var bullet_pos_parent = $"Model/bfr revolver/Bullet positions"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bullet_num = start_bullets
	start_pos = position
	for i in start_bullets:
		spawn_bullet(whole_bullet_rev, bullet_parent, bullet_positions[i].position * 100, i)
		#bullets.append(bullet_parent.get_child(i - 1))
	print(bullets)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	bullet_pos_parent.rotation = bullet_parent.get_parent().rotation
	
	time += delta
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	
	head.rotation_degrees.x = initial_rot.x + max_x * get_shake_intensity() * get_noise_from_seed(0)
	cam.rotation_degrees.y = initial_rot.y + max_y * get_shake_intensity() * get_noise_from_seed(1)
	cam.rotation_degrees.z = initial_rot.z + max_z * get_shake_intensity() * get_noise_from_seed(2)
	
	if Input.is_action_pressed("aim") and !aiming and !reloading:
		anim.play("aim")
		aiming = true
	elif Input.is_action_just_released("aim") and !reloading:
		anim.play_backwards("aim")
		aiming = false
		
	if Input.is_action_just_pressed("reload") and !reloading:
		anim.play("reload")
		reloading = true
	elif Input.is_action_just_released("reload"):
		anim.play_backwards("reload")
		reloading = false
		
	if Input.is_action_just_pressed("shoot") and aiming:
		if barrel_ray.is_colliding():
			if barrel_ray.get_collider().is_in_group("not_fired"):
				anim.play("shoot")
				var bullet_id = bullets.find(barrel_ray.get_collider())
				remove_bullet(bullet_id)
				spawn_bullet(shot_bullet_rev, bullet_parent, bullet_positions[bullet_id].position * 100, bullet_id)
				rotate_cylinder(1)
			if barrel_ray.get_collider().is_in_group("fired"):
				rotate_cylinder(1)
	if reloading:
		if Input.is_action_just_pressed("aim"):
			rotate_cylinder(-1)
		if Input.is_action_just_pressed("shoot"):
			rotate_cylinder(1)
		if Input.is_action_just_pressed("remove_bullet"):
			if ejector_ray.is_colliding():
				var bullet_id = bullets.find(ejector_ray.get_collider())
				remove_bullet(bullet_id)
				spawn_bullet(whole_bullet_rev, bullet_parent, bullet_positions[bullet_id].position * 100, bullet_id)
		
func fire():
	spawn_particle(muzzle_flash, shot_point.global_position, shot_point.global_rotation)
	spawn_particle(dust_burst, shot_point.global_position, shot_point.global_rotation)
	add_trauma(10000.0)
	SoundEmition.create_sound_area(100.0, 1, shot_point.global_position)
	if ray.is_colliding():
		if ray.get_collider().is_in_group("enemy"):
			var got_enemy = ray.get_collider()
			got_enemy.damage_enemy(got_enemy.health)
		spawn_particle(impact_spark, ray.get_collision_point(), Vector3(0, 0, 0))
		spawn_particle(dust_burst, ray.get_collision_point(), Vector3(0, 0, 0))
	
func add_trauma(trauma_amount : float):
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)
	
func get_shake_intensity() -> float:
	return trauma * trauma
	
func get_noise_from_seed(_seed : int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)
	
func spawn_particle(particle : Resource, part_position : Vector3, part_rotation : Vector3):
	var inst_particle = particle.instantiate()
	get_tree().root.add_child(inst_particle)
	inst_particle.global_position = part_position
	inst_particle.global_rotation = part_rotation
	inst_particle.emitting = true
	
func replace_bullet(ref_bullet : Resource, parent : Node3D, bullet_pos : Vector3, bullet_rot : Vector3, bullet_size : Vector3) -> Node:
	var inst_bullet = ref_bullet.instantiate()
	parent.add_child(inst_bullet)
	inst_bullet.position = bullet_pos
	inst_bullet.rotation = bullet_rot
	inst_bullet.scale = bullet_size
	parent.get_children()[weap_res.bullet_count - bullet_num].queue_free()
	parent.move_child(inst_bullet, weap_res.bullet_count - bullet_num)
	bullets[weap_res.bullet_count - bullet_num] = inst_bullet
	return inst_bullet
	
func spawn_bullet(ref_bullet : Resource, parent : Node3D, bullet_pos : Vector3, index : int):#, bullet_rot : Vector3, bullet_size : Vector3):
	var inst_bullet = ref_bullet.instantiate()
	parent.add_child(inst_bullet)
	inst_bullet.position = bullet_pos
	bullets.insert(index, inst_bullet)

func remove_bullet(index : int):
	var fired_bullet = bullets.pop_at(index)
	fired_bullet.queue_free()
	
func rotate_cylinder(mod : int):
	var cylinder = bullet_parent.get_parent()
	var new_rot = cylinder.rotation_degrees.z + (60.0 * mod)
	var rot_tween = create_tween()
	print(new_rot)
	rot_tween.tween_property(cylinder, "rotation:z", deg_to_rad(new_rot), 0.1)
