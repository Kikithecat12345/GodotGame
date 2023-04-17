extends CharacterBody3D

 # ==== global vars ====

# = movement-related constants =

# input
const MOUSE_SENSITIVITY = 0.1 

# player movement
const RUN_SPEED = 32.0 # max speeds for walking, running, and crouching respectively, in units/s.
const WALK_SPEED = 15.0
const CROUCH_SPEED = 6.33

const STEP_DISTANCE = 1.8 # max distance, in units, that the player can "step up" to without needing to jump
const JUMP_VELOCITY = 20 # initial velocity of a jump, in units/s.

# physics
const GRAVITY = 60.0 # these are in units/s^2.
const ACCELERATION = 250 
const AIR_ACCELERATION = 250
const FRICTION = 50
const MAX_SLOPE_ANGLE = 45 

# toggles
const using_abh = true  # toggles HL2 ABH, aka bugged jump speed caps
const auto_jump = true  # toggles autojump
const cap_speed = false # toggles speed cap
const SPEED_CAP = 10    # speed cap in units/s

# = internal variables =

var hVel = Vector2()
var vVel = 0

# ==== functions ====

@onready var camera = $Pivot/Camera3D
@onready var pivot = $Pivot

func _ready():
	# set mouse mode to captured
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	floor_snap_length = STEP_DISTANCE
	floor_max_angle = deg_to_rad(MAX_SLOPE_ANGLE)
	print("Version: ", ProjectSettings.get_setting("version"))

func get_wishdir():
	var dir = Vector2.ZERO
	var pivotXform = pivot.get_global_transform()
	if Input.is_action_pressed("move_forward"):
		dir.y += 1
	if Input.is_action_pressed("move_backward"):
		dir.y -= 1
	if Input.is_action_pressed("move_left"):
		dir.x += 1
	if Input.is_action_pressed("move_right"):
		dir.x -= 1
	dir = dir.normalized()
	# rotate wishdir by camera rotation
	var wishDir = Vector3()
	wishDir += pivotXform.basis.x * dir.x
	wishDir += pivotXform.basis.z * dir.y
	wishDir = wishDir.normalized()
	return Vector2(wishDir.x, wishDir.z)


func _physics_process(delta):
	# notes:
	# physics is calcuated like quake and source games, for fun.
	# read below for more info.
	var wishdir = get_wishdir()
	if is_on_floor():
		apply_friction(delta)
	# acceleration is calculated like this:
	# take the wishdir, multiply it by the acceleration, and add it to the current velocity.
	# if the dot product of the new vector is larger than the max speed, reduce the acceleration so that the new length is the max speed.
	# this is done to prevent the player from accelerating faster than the max speed, but because of the dot product, a flaw presents itself:
	# moving perpendicular to the wishdir will allow the player to accelerate unbounded, and this can be acomplished in many ways. 
	# this is the behavior that allows bunnyhopping in quake and source games, as well as other movement exploits.
	# we are intentionally keeping this behavior, because it's fun.
	
	var maxSpeed
	var accel = ACCELERATION * delta if is_on_floor() else AIR_ACCELERATION * delta
	var newHvel = hVel + wishdir * accel

	if Input.is_action_pressed("move_crouch"):
		maxSpeed = CROUCH_SPEED
	elif Input.is_action_pressed("move_sprint"):
		maxSpeed = RUN_SPEED
	else:
		maxSpeed = WALK_SPEED
	
	if newHvel.dot(wishdir) > maxSpeed:
		# scale the acceleration so that the dot product is the max speed
		accel = (maxSpeed - hVel.dot(wishdir))
		newHvel = hVel + wishdir * accel
	hVel = newHvel

	# vertical movement
	if is_on_floor():
		# check for autojump
		if auto_jump and Input.is_action_pressed("move_jump"):
			vVel = JUMP_VELOCITY
		elif Input.is_action_just_pressed("move_jump"):
			vVel = JUMP_VELOCITY
		else:
			vVel = 0
	else:
		# apply gravity
		vVel -= GRAVITY * delta
		
	velocity = Vector3(hVel.x, vVel, hVel.y)
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# rotate camera
		pivot.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		camera.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY * -1))
	if event is InputEventKey: # if escape is pressed, toggle mouse mode
		if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func apply_friction(delta):
	var speed = hVel.length()
	var drop = 0
	if speed <= 0: return;
	elif speed < FRICTION * delta:
		# if speed would be reduced past 0, reduce speed to 0
		drop = speed
	else:
		drop = FRICTION * delta
	
	var newspeed = speed - drop if speed - drop > 0 else 0
	if newspeed != speed:
		newspeed /= speed
		hVel *= newspeed


func _on_kill_plane_body_entered(_body:Node3D):
	# if the player fell off the map, we need to respawn them just above 0,0,0 so they don't get stuck in the floor.
	# i'll add walls later, this allows for testing.
	self.position = Vector3(0, 10, 0)
