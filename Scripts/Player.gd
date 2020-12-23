extends KinematicBody

export var speed: float = 10
export var jump_height: float = 6
export var acceleration: float = 10
export var mouse_sensitivity: float = .5


var direction: Vector3
var velocity: Vector3 = Vector3(0,0,0)
var fall_speed: float = 0
var snap: Vector3 = Vector3(0,0,0)

onready var head = $Head

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func movement():
	if is_on_floor():
		direction = Vector3()
		if Input.is_action_pressed("move_forward"):
			direction -= transform.basis.z
		if Input.is_action_pressed("move_backward"):
			direction += transform.basis.z
		if Input.is_action_pressed("move_left"):
			direction -= transform.basis.x
		if Input.is_action_pressed("move_right"):
			direction += transform.basis.x
			
		direction = direction.normalized()

func jump():
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			fall_speed = jump_height
			snap = Vector3(0, 0, 0)
	
func fall(delta):
	if is_on_floor():
		fall_speed = 0
		snap = Vector3(0,-1,0)
	else:
		fall_speed -= 9.8 * delta
	
func _input(event):
		#handle escaping window with mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == 2:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
func _physics_process(delta):
	movement()
	fall(delta)
	jump()
	velocity = velocity.linear_interpolate((direction * speed), acceleration * delta)
	velocity.y = fall_speed
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true)
	
