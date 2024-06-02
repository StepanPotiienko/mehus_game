extends CharacterBody3D


@onready var head = $Head
@onready var camera = $Head/Camera3D


# Movement settings.
@export var current_speed: float = 5.0
const walking_speed: float = 5.0
const sprinting_speed: float = 8.0


@export var jump_velocity: float = 4.5


@export var lerp_speed: float = 10.0


var direction: Vector3 = Vector3.ZERO


# Camera settings.
@export var mouse_sensitivity: float = 0.1;


@export var ray_length: float = 5.0


# Inventory system.
var building_blocks: int = 0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


# Executes on the start of the game (like Start() method in Unity).
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Handles the input (well no duh).
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed:
		var collided_object = shoot_ray()
		
		if collided_object:
			if collided_object.name in ["BuildingBlock", "BuildingBlock2"]:
				instance_from_id(collided_object.get_instance_id()).queue_free()
				building_blocks += 1
				print(building_blocks)


func shoot_ray() -> Object:
	# Get the size of the viewport (screen size).
	var viewport = get_viewport()
	var viewport_size = viewport.size
	var screen_center = viewport_size / 2
	
	# Create a ray from the camera at the center of the screen.
	var camera = viewport.get_camera_3d()
	var from = camera.project_ray_origin(screen_center)
	var to = from + camera.project_ray_normal(screen_center) * ray_length  # Arbitrary length.
	
	# Cast the ray.
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	
	var result = space_state.intersect_ray(query)
	
	# Check if the ray hit something.
	if result and result.collider:
		return result.collider
	
	return null


# Like FixedUpdate() in Unity.
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	
	# Handle jump.
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity


	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	if direction:
		if Input.is_action_pressed("shfit"):
			current_speed = sprinting_speed
		else:
			current_speed = walking_speed
		
		velocity.x = direction.x * current_speed 
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
