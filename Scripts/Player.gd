extends KinematicBody



export var speed_constant: float = 10
export var acceleration_constant: float = 5
export var deceleration_constant: float = 10

export var jump_height: float = 5
export var jump_lateral_speed: float = 5
export var gravity: float = 9.8

export(Curve) var acceleration_curve
export(Curve) var slide_curve
export(Curve) var wallrun_profile
export(Curve) var wallclimb_profile

export var mouse_sensitivity: float = .1

onready var speed: float = speed_constant
var acceleration: float = acceleration_constant
var deceleration: float = deceleration_constant
var direction: Vector3
var velocity: Vector3 = Vector3(0,0,0)
var fall_speed: float = 0
var snap: Vector3 = Vector3(0,0,0)
var slope_stop: bool = true
onready var phys_location = global_transform.origin

var wallrun: bool = false
var sprint: bool = false
var climbing: bool = false
var sliding: bool = false
var can_wall_move: bool = true


onready var body = $display
onready var animation_player = $display/AnimationPlayer
onready var head = $display/Head
onready var camera = $display/Head/Camera
onready var ledge_raycast = $Colliders/LedgeRayCast

#timer references
onready var wallrun_timer = $Timers/WallRunTimer
onready var climber_timer = $Timers/WallClimbTimer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func movement_input():
	direction = Vector3(0,0,0)
	#if is_on_floor():
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
		
	direction = direction.normalized()

#add some form of yield to crouch animation so player can't spam slide boost
func crouch():
	if Input.is_action_just_pressed("crouch"):
		speed = speed_constant / 2
		acceleration = acceleration_constant / 2
		slope_stop = false
		animation_player.play("Crouch")


	if Input.is_action_pressed("crouch"):
		var speed_offset: float = velocity.length() / speed
		var deceleration_offset: float = self.slide_curve.interpolate(speed_offset)
		deceleration = deceleration_constant * deceleration_offset
	if Input.is_action_just_released("crouch"):
		slope_stop = true
		speed = speed_constant
		acceleration = acceleration_constant
		deceleration = deceleration_constant
		animation_player.play_backwards("Crouch")

func wall_angle():
	if not is_on_floor():
		if is_on_wall():
			var wall_collision = get_slide_collision(0)
			return wall_collision.normal

#do this if player inputs crouch at > x% speed
func slide():
	#animate fov narrowing
	pass

func wall_mount():
	if not ledge_raycast.is_colliding():
		pass
	
func vault():
	pass

func wall_listener():
	if is_on_floor():
		can_wall_move = true
	if can_wall_move:
		if not is_on_floor():
			if direction.length() > 0:
				if is_on_wall():
					var wall_angle = get_slide_collision(0).normal
					if not wallrun and not climbing:
						if wall_angle.dot(velocity) > -0.7 and velocity.length() > speed / 2 and climbing == false:
							wallrun = true
							wallrun_timer.start()
						if velocity.y > 0:
							if wall_angle.dot(direction) < -0.8 and wallrun == false:
								climbing = true
					wall_reverse()
					wall_jump()
					print(rotation)
			

func wall_run():
	if wallrun == true:
		if direction != Vector3(0,0,0) and is_on_wall() and pow(velocity.x, 2) + pow(velocity.z, 2) > .3:
			var timer_complete = (wallrun_timer.wait_time - wallrun_timer.time_left) / wallrun_timer.wait_time
			velocity += -wall_angle() * 0.1
			fall_speed = (wallrun_profile.interpolate(timer_complete) -0.5) * 2
			return true
		else:
			wallrun = false

#do this if wall collider normal dot movement vector is closer to -1
func wall_climb():
	if climbing == true:
		if direction.length() > 0.5 and is_on_wall():
			fall_speed = 5
			velocity += -wall_angle() * 0.4
		else:
			climbing = false

#TODO only jump if facing away from wall
#if wall collider normal dot movement vector is closer to 1
func wall_jump():
	if Input.is_action_just_pressed("jump"):
		velocity = (direction.rotated(Vector3(1,0,0), -1 * head.rotation.x))
		velocity = Vector3(velocity.x * speed, (head.rotation.x/(PI/2) + 0.5) * jump_height, velocity.z * speed)
		fall_speed = velocity.y
		print("jump")
		wallrun = false
		wallrun_timer.stop()
		can_wall_move = true


func wall_reverse():
	if Input.is_action_just_pressed("player_ability_2"):
		rotate(Vector3.UP, PI)

func jump():
	if Input.is_action_just_pressed("jump"):
		snap = Vector3(0, 0, 0)
		if is_on_floor():
			fall_speed = jump_height
			if velocity.length() < jump_lateral_speed and direction != Vector3(0,0,0):
				velocity = direction * jump_lateral_speed

	
func fall(delta):
	if is_on_floor():
		fall_speed = velocity.y - 0.01
		snap = Vector3(0,-1,0)
	else:
		fall_speed -= gravity * delta


func movement(delta):
	var speed_offset: float = velocity.length() / speed
	var acceleration_offset: float = self.acceleration_curve.interpolate(speed_offset)
	if is_on_floor():
		if direction.length() == 1:
			velocity = velocity.linear_interpolate((direction * speed), acceleration_offset * acceleration * delta)
		else:
			velocity = velocity.linear_interpolate((direction * speed), deceleration * delta)

	velocity.y = fall_speed

	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, slope_stop, 4, 1)
	phys_location = global_transform.origin

func frame_interpolation():
	var phys_frames = ProjectSettings.get_setting("physics/common/physics_fps")
	var fps = Engine.get_frames_per_second()
	if fps > phys_frames:
		body.set_as_toplevel(true)
		body.global_transform.origin = body.global_transform.origin.linear_interpolate(phys_location, Engine.get_physics_interpolation_fraction())
		body.rotation = rotation
	else:
		body.global_transform = global_transform
		body.set_as_toplevel(false)
	
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
	wall_listener()
	movement_input()
	crouch()
	fall(delta)
	jump()
	wall_run()
	wall_climb()
	movement(delta)

	phys_location = translation

func _process(delta):
	frame_interpolation()
	pass




#Timer Signals Here
func _on_WallRunTimer_timeout():
	wallrun = false
	can_wall_move = false
	print("fall")


func _on_WallClimbTimer_timeout():
	pass # Replace with function body.
