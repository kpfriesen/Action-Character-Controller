extends KinematicBody

export var speed: float = 10
export var jump_height: float = 6
export var acceleration: float = 5
export var deceleration: float = 10
export(Curve) var acceleration_curve
export var mouse_sensitivity: float = .1


var direction: Vector3
var velocity: Vector3 = Vector3(0,0,0)
var fall_speed: float = 0
var snap: Vector3 = Vector3(0,0,0)
var phys_location = Vector3()

onready var body = $display
onready var head = $display/Head

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func movement_input():
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

func movement(delta):
	var speed_offset: float = velocity.length() / speed
	var acceleration_offset: float = self.acceleration_curve.interpolate(speed_offset)
	if is_on_floor():
		if direction.length() == 1:
			velocity = velocity.linear_interpolate((direction * speed), acceleration_offset * acceleration * delta)
		else:
			velocity = velocity.linear_interpolate((direction * speed), deceleration * delta)
	velocity.y = fall_speed
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true)
	
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
	movement_input()
	fall(delta)
	jump()
	movement(delta)
	phys_location = translation

func _process(delta):
	var phys_frames = ProjectSettings.get_setting("physics/common/physics_fps")
	var fps = Engine.get_frames_per_second()
	var offset_amount = velocity * delta
	var smooth_position = global_transform.origin + offset_amount

	if fps > phys_frames:
		body.set_as_toplevel(true)
		body.global_transform.origin = body.global_transform.origin.linear_interpolate(smooth_position, Engine.get_physics_interpolation_fraction())
		body.rotation = rotation
		
	else:
		body.global_transform = global_transform
		body.set_as_toplevel(false)


