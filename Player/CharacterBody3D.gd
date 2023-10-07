extends CharacterBody3D

var speed
var CROUCH_DEPTH = -0.5
const WALK_SPEED = 2
const SPRINT_SPEED = 4
const CROUCH_SPEED = 1
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.002

#bob variables
const BOB_FREQ = 3.2
const BOB_AMP = 0.04
var t_bob = 0.0

#fov variables
const BASE_FOV = 50
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8


@onready var head = $Head

@onready var camera := $Head/Camera3D

@onready var flashlight := $Head/Camera3D/SpotLight3D
@onready var ditherCam := $Head/Camera3D/SubViewportContainer/SubViewport/Camera3D
@onready var ditherViewport := $Head/Camera3D/SubViewportContainer/SubViewport
#variables for crouching
@onready var stand = $Stand
@onready var crouch = $Crouch
@onready var ray_cast_3d = $RayCast3D

#Mouse capture and camera control
func _unhandled_input(event):
	if event.is_action_pressed("fire"): #capture mouse on fire
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"): #free mouse on pause
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: #Update camera pos on mouse move
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(75)) #Clamping camera
			
#Character movement code
func _physics_process(delta):
	
	#crouch and sprint code
	if Input.is_action_pressed("crouch"):
		speed = CROUCH_SPEED
		head.position.y = lerp(head.position.y,0.6 + CROUCH_DEPTH,delta*10)
		stand.disabled = true
		crouch.disabled = false
	elif !ray_cast_3d.is_colliding():
		crouch.disabled = true
		stand.disabled = false
		head.position.y = lerp(head.position.y,0.6,delta*10)
		
		if Input.is_action_pressed("sprint"):
			speed = SPRINT_SPEED
		else:
			speed = WALK_SPEED
		
		
	
	
	#synch cam with viewport
	ditherCam.global_transform = camera.global_transform
	ditherViewport.size = DisplayServer.window_get_size()
	#toggle flashlight
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = not flashlight.visible
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Sprint.


	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 4.0)

	move_and_slide()

#Headbob Function
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
