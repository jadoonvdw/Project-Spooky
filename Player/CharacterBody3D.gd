extends CharacterBody3D

#General movement variables
var speed
var CROUCH_DEPTH = -0.5
const WALK_SPEED = 2
const SPRINT_SPEED = 4
const CROUCH_SPEED = 1
const JUMP_VELOCITY = 4.8

#Headbob variables
const BOB_FREQ = 3.2
const BOB_AMP = 0.04
var t_bob = 0.0

#Camera variables
const BASE_FOV = 50
const FOV_CHANGE = 1.5
const SENSITIVITY = 0.002

#Footstep sound variables / Shoutout to Dragon20C on youtube for the easy tutorial on this
var can_play : bool = true
signal step

#Gravity variable
var gravity = 9.8

#Head and Camera nodes
@onready var head = $Head
@onready var camera := $Head/Camera3D

#Flashlight nodes
@onready var flashlight := $Head/Camera3D/SpotLight3D
@onready var flashlightClick := $Head/Camera3D/SpotLight3D/flashlightClick

#Dither Effect nodes
@onready var ditherCam := $Head/Camera3D/SubViewportContainer/SubViewport/Camera3D
@onready var ditherViewport := $Head/Camera3D/SubViewportContainer/SubViewport

#Crouching nodes
@onready var stand = $Stand
@onready var crouch = $Crouch
@onready var ray_cast_3d = $RayCast3D

#Mouse capture and camera control
func _unhandled_input(event):
	if event.is_action_pressed("fire"): #Capture mouse on fire
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"): #Free mouse on pause
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	#Update camera pos on mouse move
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: 
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			
			#Clamping camera rotation to prevent over rotation
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(75)) 

#Character movement code updating every frame
func _physics_process(delta):
	
	#Crouch elif statement to check collision
	if Input.is_action_pressed("crouch"):
		speed = CROUCH_SPEED
		head.position.y = lerp(head.position.y,0.6 + CROUCH_DEPTH,delta*10)
		stand.disabled = true
		crouch.disabled = false
		
	#Elif here checks if standing isnt blocked with the ! and makes u stand
	elif !ray_cast_3d.is_colliding():
		crouch.disabled = true
		stand.disabled = false
		head.position.y = lerp(head.position.y,0.6,delta*10)

	#Sprint if statement
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	#Sync dithering viewport with camera
	ditherCam.global_transform = camera.global_transform
	ditherViewport.size = DisplayServer.window_get_size()
	
	#Flashlight toggle and click sound
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = not flashlight.visible
		
	#Gravity check
	if not is_on_floor():
		velocity.y -= gravity * delta

	#Get input direction and use it find true direction relative to new head pos
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#Walking If statement
	if is_on_floor():
		#Moves character in direction 
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		#Smoothes out character deceleration
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	#Else statement slows character down in the air 
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	#Head bob positions every frame
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 4.0)
	
	#End func by updating character position
	move_and_slide()

#Headbob Function
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	
	#Number subtracted from BOB_AMP changes timing of footstep audio 
	var low_pos = BOB_AMP - 0.04 
	
	#Signal spam prevention and footstep audio playing (can_play prevents signal spam)
	#Reset can_play on high headbob position 
	if pos.y > -low_pos:
		can_play = true
	#Disable can_play and play footstep audio on low headbob position
	if pos.y < -low_pos and can_play:
		can_play = false
		emit_signal("step")
	
	return pos
