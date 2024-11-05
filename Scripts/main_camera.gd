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
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if mouseButtonMiddlePressed:
		mainCamera.position = Vector3(((camPositionStartMove.x+(mousePositionForMiddle.y*(mainCamera.position.y/500))) - (get_viewport().get_mouse_position().y*(mainCamera.position.y/500))),
		camPositionStartMove.y,
		((camPositionStartMove.z-(mousePositionForMiddle.x*(mainCamera.position.y/500))) + (get_viewport().get_mouse_position().x*(mainCamera.position.y/500))))
		
	

		
var mousePositionForLeft = Vector2()
var mousePositionForMiddle = Vector2()
var camPositionStartMove = Vector3()
var camPositionStartWheel = Vector3()
var camPositionTargetWheel = Vector3()
var selectFirstPoint = Vector3()
var selectSecondPoint = Vector3()
var rayStart
var rayEnd

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			mousePositionForMiddle = get_viewport().get_mouse_position()
			camPositionStartMove = mainCamera.position
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
			rayStart = mainCamera.project_ray_origin(event.position)
			rayEnd = rayStart + mainCamera.project_ray_normal(event.position) * RAY_LENGTH
			
			if space_state != null:
				var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1)
				if space_state.intersect_ray(query).has("position"): 
					workDistributor.movePlayer(space_state.intersect_ray(query).position)
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mouseButtonLeftPressed = true
			
			mousePositionForLeft = get_viewport().get_mouse_position()
			
			rayStart = mainCamera.project_ray_origin(event.position)
			rayEnd = rayStart + mainCamera.project_ray_normal(event.position) * RAY_LENGTH
			
			if space_state != null:
				var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1)
				if space_state.intersect_ray(query).has("position"): 
					selectFirstPoint = space_state.intersect_ray(query).position

		elif event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			mouseButtonLeftPressed = false
			
			rayStart = mainCamera.project_ray_origin(event.position)
			rayEnd = rayStart + mainCamera.project_ray_normal(event.position) * RAY_LENGTH
			
			if space_state != null:
				var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1)
				if space_state.intersect_ray(query).has("position"): 
					selectSecondPoint = space_state.intersect_ray(query).position
					workDistributor.mouseSelect(selectFirstPoint, selectSecondPoint)
