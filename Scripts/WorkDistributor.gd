extends Node

@onready var entitys = $Entitys
@onready var firstPointBox = $MeshInstance3D
@onready var secondPointBox = $MeshInstance3D2



func _ready() -> void:
	createMap()

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


var map: RID
func createMap():
	map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_up(map, Vector3.UP)
	NavigationServer3D.map_set_active(map, true)
	
	var region: RID = NavigationServer3D.region_create()
	NavigationServer3D.region_set_transform(region, Transform3D())
	NavigationServer3D.region_set_map(region, map)
	
	var new_navigation_mesh: NavigationMesh = NavigationMesh.new()
	new_navigation_mesh = $NavigationRegion3D.navigation_mesh

	NavigationServer3D.map_set_cell_height(map,1)
	NavigationServer3D.region_set_navigation_mesh(region, new_navigation_mesh)

func getPath(startPoint, finalPoint):
	return NavigationServer3D.map_get_path(map,startPoint,finalPoint,true)
