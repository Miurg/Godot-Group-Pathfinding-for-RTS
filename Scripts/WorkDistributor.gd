extends Node

@onready var entitys = $Entitys
@onready var firstPointBox = $MeshInstance3D
@onready var secondPointBox = $MeshInstance3D2

var ramerDouglasPeuckerValue = 0.5


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
	NavigationServer3D.map_set_cell_size(map, 0.17)
	
	var new_navigation_mesh: NavigationMesh = NavigationMesh.new()
	new_navigation_mesh = $NavigationRegion3D.navigation_mesh

	NavigationServer3D.map_set_cell_height(map,1)
	NavigationServer3D.region_set_navigation_mesh(region, new_navigation_mesh)

func getPath(startPoint, finalPoint):
	var path = ramer_douglas_peucker(NavigationServer3D.map_get_path(map,startPoint,finalPoint,true),ramerDouglasPeuckerValue)
	return path
	
	
static func ramer_douglas_peucker(points: PackedVector3Array, epsilon: float) -> PackedVector3Array:
	if points.size() < 3:
		return points.duplicate()
	var epsilon_squared = pow(epsilon, 2)	
	var result := PackedVector3Array()
	_simplify(result, points, 0, points.size() - 1, epsilon_squared)
	result.append(points[-1])
	return result

# Recursive calculation
static func _simplify(result: PackedVector3Array, points: PackedVector3Array, start: int, end: int, epsilon_squared: float) -> void:
	var max_distance_squared = 0
	var index = 0
	
	for i in range(start, end + 1):
		var distance = _perpendicular_squared(points[i], points[start], points[end])
		if distance > max_distance_squared:
			max_distance_squared = distance
			index = i
	
	if max_distance_squared <= epsilon_squared:
		result.append(points[start])
	else:
		_simplify(result, points, start, index, epsilon_squared)
		_simplify(result, points, index, end, epsilon_squared)

static func _perpendicular_squared(target: Vector3, p1: Vector3, p2: Vector3) -> float:
	var to_target = target - p1
	var to_end = p2 - p1
	var project = to_target.project(to_end)
	return to_target.length_squared() - project.length_squared()
