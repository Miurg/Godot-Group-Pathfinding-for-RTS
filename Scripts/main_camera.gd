extends Node

const RAY_LENGTH = 1000.0

@onready var workDistributor = $".."
@onready var mainCamera: Camera3D = $"."
var space_state
# Called when the node enters the scene tree for the first time.
		
		

func _ready():
	space_state = get_tree().get_root().get_world_3d().direct_space_state
	pass # Replace with function body.
	
var mouseButtonMiddlePressed = false
var mouseButtonLeftPressed = false
var camMoveForX
var camMoveForZ
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if mouseButtonMiddlePressed:
		rayStart = mainCamera.project_ray_origin(get_viewport().get_mouse_position())
		rayEnd = rayStart + mainCamera.project_ray_normal(get_viewport().get_mouse_position()) * RAY_LENGTH
		if space_state != null:
			var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1)
			if space_state.intersect_ray(query).has("position"): 
				rayPosition = space_state.intersect_ray(query).position
		
		mainCamera.position = Vector3((mainCamera.position.x+(mousePositionForMiddeLast.x - rayPosition.x)),
		mainCamera.position.y,
		(mainCamera.position.z+(mousePositionForMiddeLast.z - rayPosition.z)))

var mousePositionForLeft = Vector2()
var mousePositionForMiddleCurrent = Vector3()
var mousePositionForMiddeLast = Vector3()
var camPositionStartMove = Vector3()
var camPositionStartWheel = Vector3()
var camPositionTargetWheel = Vector3()
var selectFirstPoint = Vector3()
var selectSecondPoint = Vector3()
var rayStart
var rayEnd
var rayPosition

func _input(event):
	if event is InputEventMouseButton:
		rayStart = mainCamera.project_ray_origin(get_viewport().get_mouse_position())
		rayEnd = rayStart + mainCamera.project_ray_normal(get_viewport().get_mouse_position()) * RAY_LENGTH
		if space_state != null:
			var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1)
			if space_state.intersect_ray(query).has("position"): 
				rayPosition = space_state.intersect_ray(query).position
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			mousePositionForMiddeLast = rayPosition
			mouseButtonMiddlePressed = true
		else: 
			mouseButtonMiddlePressed = false 
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camPositionTargetWheel = mainCamera.transform.translated_local(Vector3(0,0,-1))
			mainCamera.transform = camPositionTargetWheel
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camPositionTargetWheel = mainCamera.transform.translated_local(Vector3(0,0,1))
			mainCamera.transform = camPositionTargetWheel
			
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			workDistributor.movePlayer(rayPosition)
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mouseButtonLeftPressed = true
			selectFirstPoint = rayPosition

		elif event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			mouseButtonLeftPressed = false
			selectSecondPoint = rayPosition
			workDistributor.mouseSelect(selectFirstPoint, selectSecondPoint)
