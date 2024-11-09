extends Node

@onready var entitys = $Entitys
@onready var firstPointBox = $MeshInstance3D
@onready var secondPointBox = $MeshInstance3D2



func _ready() -> void:
	pass

var trueFirstPoint = Vector2()
var trueSecondPoint = Vector2()
func mouseSelect(firstPoint, secondPoint):
	if (firstPoint.x<secondPoint.x):
		trueFirstPoint.x = firstPoint.x
		trueSecondPoint.x = secondPoint.x
	else:
		trueFirstPoint.x = secondPoint.x
		trueSecondPoint.x = firstPoint.x
	if (firstPoint.z>secondPoint.z):
		trueFirstPoint.y = firstPoint.z
		trueSecondPoint.y = secondPoint.z
	else:
		trueFirstPoint.y = secondPoint.z
		trueSecondPoint.y = firstPoint.z
	firstPointBox.set_position(Vector3(trueFirstPoint.x,2,trueFirstPoint.y))
	secondPointBox.set_position(Vector3(trueSecondPoint.x,2,trueSecondPoint.y))
	entitys.findSelected(trueFirstPoint,trueSecondPoint)
	
var selectedEntitys = []

func movePlayer(position:Vector3):
	for i in selectedEntitys:
		i.moveMarker(position)
