extends CharacterBody3D

 # global vars

const MOVE_SPEED = 5
const GRAVITY = 9.8
const MOUSE_SENSITIVITY = 0.1
var vel = Vector3.ZERO
var vVel = 0

var camera
var pivot

 # functions

func _ready():
	camera = $Pivot/Camera3D
	pivot = $Pivot
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_dir():
	var inputs = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		inputs.x += 1
	if Input.is_action_pressed("move_right"):
		inputs.x -= 1
	if Input.is_action_pressed("move_forward"):
		inputs.y += 1
	if Input.is_action_pressed("move_backward"):
		inputs.y -= 1
	# rotate to camera direction
	var dir = Vector3.ZERO
	var pivotXform = pivot.get_global_transform()
	dir += pivotXform.basis.z * inputs.y
	dir += pivotXform.basis.x * inputs.x
	dir.y = 0
	return dir.normalized()

func _input(event):
	# ==== camera ====
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		camera.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY))

func _physics_process(delta):
	vel = Vector3.ZERO
	# ==== x/z movement ==== 
	vel = get_dir() * MOVE_SPEED * (delta*100)
	# ==== y movement ==== 
	if is_on_floor():
		if Input.is_action_pressed("move_jump"):
			vVel = 5
	else:
		vVel -= GRAVITY * delta
	vel.y = vVel
	velocity = vel
	move_and_slide()
