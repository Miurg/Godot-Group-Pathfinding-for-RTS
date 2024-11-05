extends Node3D

var movement_speed = 5
var movement_accel = 10

@onready var marker: Marker3D = $Marker3D
@onready var selectedTorus = $Selected
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var thread: Thread
func _ready():
	await get_tree().physics_frame
	navigation_agent.target_position = marker.position
	

func _physics_process(delta):
	var next_path = navigation_agent.get_next_path_position()
	global_position = global_position.move_toward(next_path, delta * movement_speed)
	pass
	
	
func moveMarker(newPosition:Vector3):
	marker.position = newPosition
	navigation_agent.target_position = marker.position
	
func selectedTrue():
	selectedTorus.visible = true

func selectedFalse():
	selectedTorus.visible = false
