extends CharacterBody3D
const SPEED = 8.0
const JUMP_VELOCITY = 6.5
const SENSITIVITY = 0.01

const BOB_FREQ = 1.0
const BOB_AMP = 0.1

var t_bob = 0.0

@export var lean_ammount : float
@export var friction_lerp_amount : float

@export var weapon_rot_amount = 1.0

@export var pickup_object_pos : Node3D
var held_object : Object
var dragged_object : Object

var lean_multiplier : float

var p_health := 100.0

@onready var head = $Head
@onready var cam = $Head/Camera3D
@onready var initial_cam_pos = cam.position

@onready var weapon_holder = $Head/Camera3D/Weapon_holder

@onready var ray = $Head/Camera3D/RayCast3D

@onready var inventory = $"Inventory manager/Inventory/ScrollContainer/VBoxContainer"

var def_weapon_holder_pos : Vector3
var def_cam_pos : Vector3

var direction = Vector3.ZERO

var cam_offset : float

var base_fov : float
var target_fov = 1.0

var mouse_input : Vector2
var input_dir : Vector2

var starting_scale : Vector3
var current_speed : float
var running_speed : float

var interacting = false

var paused = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	current_speed = SPEED
	running_speed = SPEED * 2
	base_fov = cam.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	starting_scale = scale
	def_weapon_holder_pos = weapon_holder.position
	def_cam_pos = cam.position
	held_object = null
	inventory.hide()

func _input(event):
	if (event is InputEventMouseMotion) and !interacting and !inventory.visible:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		cam.rotate_x(-event.relative.y * SENSITIVITY)
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		mouse_input = event.relative
	
	if Input.is_action_just_pressed("pause"):
		if interacting:
				interacting = false
				var computer = ray.get_collider()
				computer.interacting = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			if !paused:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				paused = true
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				paused = false
			
	if Input.is_action_just_pressed("inventory"):
		if inventory.visible:
			inventory.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			inventory.show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	if Input.is_action_just_pressed("interact"):
		if ray.get_collider().is_in_group("switch"):
				ray.get_collider().switch_switch()
		if ray.get_collider().is_in_group("computer"):
			if !interacting:
				var computer = ray.get_collider()
				head.global_position = computer.cam_pos.global_position
				head.global_rotation = computer.cam_pos.global_rotation
				cam.global_position = computer.cam_pos.global_position
				cam.global_rotation = computer.cam_pos.global_rotation
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				computer.interacting = true
				interacting = true
	

var onGround = true

func _process(delta: float) -> void:
	if input_dir != Vector2.ZERO and !Input.is_action_pressed("aim"):
		weapon_bob(velocity.length(), delta)	
	weapon_sway(delta)
	weapon_sway_rot(delta)
	
	if Input.is_action_just_pressed("interact"):
		if ray.is_colliding():
			if ray.get_collider().is_in_group("movable"):
				pick_up_object(ray.get_collider())
			if ray.get_collider().is_in_group("item"):
				inventory.add_item(ray.get_collider())
				ray.get_collider().queue_free()
			
	
	drag_object(delta)
	
	if held_object:
		held_object.global_position = pickup_object_pos.global_position

func _physics_process(delta):
	if !interacting:
		# Add the gravity.c
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		input_dir = Input.get_vector("left", "right", "up", "down")
		direction = lerp(direction,(head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * friction_lerp_amount)
		
		if dragged_object == null:
			if direction:
				velocity.x = direction.x * current_speed
				velocity.z = direction.z * current_speed
			else:
				velocity.x = move_toward(velocity.x, 0, current_speed)
				velocity.z = move_toward(velocity.z, 0, current_speed)
			
		#print(current_speed)
			
		if Input.is_action_pressed("crouch"):
			scale.y = lerpf(scale.y, 0.5, delta * friction_lerp_amount)
		else:
			scale.y = lerpf(scale.y, starting_scale.y, delta * friction_lerp_amount)
		
		if cam_offset != 0.0:
			cam.v_offset = lerpf(cam.v_offset, cam_offset / 10, 5 * delta)
			
		if cam_offset < 0:
			cam_offset = lerpf(cam_offset, 0, 5 * delta)
			
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
			cam_offset = minf(velocity.y ,2.0)
		
		if !Input.is_action_pressed("check_frequency"):
			if Input.is_action_pressed("lean_right"):
				lean_multiplier = -1
				rotate_camera(delta)	
			if Input.is_action_pressed("lean_left"):
				lean_multiplier = 1
				rotate_camera(delta)	
				
			elif !Input.is_action_pressed("lean_right") and !Input.is_action_pressed("lean_left"):
				var tween = get_tree().create_tween()
				tween.tween_property(head, "rotation:z", 0.0, 0.1)
				#head.rotation.z = deg_to_rad(lerp_angle(head.rotation.z, 0, delta * 10))
			
		if Input.is_action_pressed("sprint"):
			current_speed = running_speed
		if Input.is_action_just_released("sprint"):
			current_speed = SPEED
			
		if is_on_floor():
			if !onGround:
				offset_cam_on_fall(delta)
				#landing_sfx.play()
			onGround = true
		else:
			onGround = false

		move_and_slide()
		
		for col_idx in get_slide_collision_count():
			var col = get_slide_collision(col_idx)
			if col.get_collider() is RigidBody3D:
				col.get_collider().apply_central_impulse(-col.get_normal() * 0.3)
				col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position())
		
		t_bob += delta * velocity.length() * float(is_on_floor())
		cam.transform.origin = _headbob(t_bob)

func rotate_camera(delta):
	var tween = get_tree().create_tween()
	tween.tween_property(head, "rotation:z", deg_to_rad(lean_ammount * lean_multiplier), 0.1)
	#head.rotation.z = deg_to_rad(lerp_angle(head.rotation.z, lean_ammount * lean_multiplier, delta * 500))
	
func _headbob(time) -> Vector3:
	var pos = initial_cam_pos
	pos.y = initial_cam_pos.y + sin(time * BOB_FREQ) * BOB_AMP
	return pos
	
func offset_cam_on_fall(delta):
	if velocity.y < 0.5:
		cam.v_offset = lerpf(cam.v_offset + cam_offset / 50, cam_offset / 5, 5 * delta)
	
func weapon_sway(delta):
	mouse_input = lerp(mouse_input, Vector2.ZERO, 10 * delta)
	var final_pos = Vector3(mouse_input.x, mouse_input.y, 0.0) * weapon_rot_amount
	weapon_holder.position = lerp(weapon_holder.position, final_pos + def_weapon_holder_pos, 10 * delta)

func weapon_sway_rot(delta):
	mouse_input = lerp(mouse_input, Vector2.ZERO, 10 * delta)
	weapon_holder.rotation.x = lerp(weapon_holder.rotation.x, mouse_input.y * weapon_rot_amount, 10 * delta)
	weapon_holder.rotation.y = lerp(weapon_holder.rotation.y, mouse_input.x * weapon_rot_amount, 10 * delta)
	
func weapon_bob(vel : float, delta):
	if weapon_holder:
		if vel > 0 and is_on_floor():
			var bob_amount = 0.1
			var bob_freq = 0.01
			weapon_holder.position.y = lerp(weapon_holder.position.y, def_weapon_holder_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount, 10 * delta)
			weapon_holder.position.x = lerp(weapon_holder.position.x, def_weapon_holder_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount, 10 * delta)
			
		else:
			weapon_holder.position.y = lerp(weapon_holder.position.y , def_weapon_holder_pos.y, 10 * delta)
			weapon_holder.position.x = lerp(weapon_holder.position.x , def_weapon_holder_pos.x, 10 * delta)
			
func heal_player(health : float):
	p_health += health
	
func damage_player(damage : float):
	p_health -= damage
	if p_health <= 0.0:
		print("ded")
		
func pick_up_object(object):
	if held_object:
		object.sleeping = false
		object.collision_mask = 1
		held_object = null
	else:
		object.sleeping = true
		object.collision_mask = 0
		held_object = object

func drag_object(delta):
	if Input.is_action_pressed("interact"):
		if ray.is_colliding():
			if ray.get_collider().is_in_group("draggable") and ray.get_collider() != null:
				dragged_object = ray.get_collider()
				var drag_force = lerp(direction,(head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta) * dragged_object.mass
				dragged_object.apply_central_force(drag_force * (15 / dragged_object.mass))
				velocity.z = drag_force.z
				velocity.x = drag_force.x
			else:
				dragged_object = null
	if Input.is_action_just_released("interact"):
		dragged_object = null
