extends Node3D

@onready var mapAndPath = $"../../Map"

var sizeOfSquad:int = 300
var allChildMainMesh:Array[RID]
var allChildSelectMesh:Array[RID]
var allChildMainMeshPosition:Array[Transform3D]
var allChildSelectMeshPosition:Array[Transform3D]
var capsuleMesh = load("res://Mesh/2untitled.obj")
var torusMesh = load("res://Select.tres")

var allSquadPath:PackedVector3Array
var currentPath:Array[Vector3]
var allPath:Array[PackedVector3Array]
var pathComplete:Array[bool]

var numberOfPathForEach:Array[int]
var localPositionOfUnit:Array[Array]
var centerPositionOfSquad:Vector3 = Vector3(0,0,0)

#z> = 0, z< = 1, x> = 2, x< = 3
var rectangleSquadPos = [0,0,0,0]
var rectangleSquad
var rectangleMesh = load("res://Box.tres")

@onready var squadAgent = $NavigationAgent3D

var formationPositions:Array[Vector2] 
var formationHorizontalSize:int = 30
var formationSpred:float = 1
var formationAngleToPath:Array[float]

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in sizeOfSquad:
		var instanceMain = RenderingServer.instance_create()
		var instanceSelect = RenderingServer.instance_create()
		var scenario = get_world_3d().scenario
		RenderingServer.instance_set_scenario(instanceMain, scenario)
		RenderingServer.instance_set_scenario(instanceSelect, scenario)
			
		RenderingServer.instance_set_base(instanceMain, capsuleMesh)
		RenderingServer.instance_set_base(instanceSelect, torusMesh)
			
		var xformMain = Transform3D(Basis(), Vector3(0, 0, 0))
		var xformSelect = Transform3D(Basis(), Vector3(0, 19, 0))
			
		RenderingServer.instance_set_transform(instanceMain, xformMain)
		RenderingServer.instance_set_transform(instanceSelect, xformSelect)
			
		allChildMainMeshPosition.append(xformMain)
		allChildSelectMeshPosition.append(xformSelect)
			
		RenderingServer.instance_set_visible(instanceSelect,false)
			
		allChildMainMesh.append(instanceMain)
		allChildSelectMesh.append(instanceSelect)
			
		
	var Horizontal = -1
	var Vertical = 0
	for i in allChildMainMesh.size():
		if Horizontal == formationHorizontalSize-1:
			Vertical+=1
			Horizontal=0
		else: Horizontal+=1
		formationPositions.append(Vector2(Vertical*formationSpred,(Horizontal*formationSpred)-(formationHorizontalSize*formationSpred)/2))
		
		pathComplete.append(true)
		numberOfPathForEach.append(0)
		
		
	rectangleSquad = RenderingServer.instance_create()
	RenderingServer.instance_set_scenario(rectangleSquad, get_world_3d().scenario)
	RenderingServer.instance_set_base(rectangleSquad, rectangleMesh)
	RenderingServer.instance_set_transform(rectangleSquad, Transform3D(Basis(), Vector3(5, 2, 5)))
	rectangleProcess()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	findPathForEachUnit(centerPositionOfSquad)
	space_state = get_tree().get_root().get_world_3d().direct_space_state
var space_state

	

func _process(delta):
	squadAgent.get_next_path_position()
	if currentPath.size()==0:
		return
	checkAndMove(delta)
	rectangleProcess()
	global_position = centerPositionOfSquad



func checkAndMove(delta):
	for i in allChildMainMesh.size():
		if allChildMainMeshPosition[i].origin==currentPath[i]:
			pathComplete[i] = true
		if pathComplete[i] and !allPath[i].is_empty():
			pathComplete[i] = false
			currentPath[i] = allPath[i][0]
			allPath[i].remove_at(0)
		elif pathComplete[i] and allPath[i].is_empty():
			if numberOfPathForEach[i]>0:
				findPathForOneUnit(allSquadPath[allSquadPath.size()-numberOfPathForEach[i]], i,allSquadPath.size()-numberOfPathForEach[i])
			pathComplete[i] = false
			numberOfPathForEach[i]-=1
		if !pathComplete[i]:
			allChildMainMeshPosition[i] = Transform3D(Basis(),
				allChildMainMeshPosition[i].origin.move_toward(currentPath[i], delta * 10))
			RenderingServer.instance_set_transform(allChildMainMesh[i], allChildMainMeshPosition[i])
			RenderingServer.instance_set_transform(allChildSelectMesh[i], 
			Transform3D(Basis(),Vector3(allChildMainMeshPosition[i].origin.x,
			allChildMainMeshPosition[i].origin.y-1,
			allChildMainMeshPosition[i].origin.z)))
			#var rayStart = allChildMainMeshPosition[i].origin*10
			#var rayEnd = rayStart + allChildMainMeshPosition[i].origin * 1000
			#if space_state != null:
				#var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1)
				#if space_state.intersect_ray(query).has("position"): 
					#var rayPosition = space_state.intersect_ray(query).position

func rectangleProcess():
	for i in allChildMainMesh.size():
		if allChildMainMeshPosition[i].origin.z > rectangleSquadPos[0]:
			rectangleSquadPos[0] = allChildMainMeshPosition[i].origin.z
		elif allChildMainMeshPosition[i].origin.z < rectangleSquadPos[1]:
			rectangleSquadPos[1] = allChildMainMeshPosition[i].origin.z
		if allChildMainMeshPosition[i].origin.x > rectangleSquadPos[2]:
			rectangleSquadPos[2] = allChildMainMeshPosition[i].origin.x
		elif allChildMainMeshPosition[i].origin.x < rectangleSquadPos[3]:
			rectangleSquadPos[3] = allChildMainMeshPosition[i].origin.x
	var distanceX
	var distanceZ 
	if rectangleSquadPos[1]<0 and rectangleSquadPos[0]>0:
		distanceX = abs(rectangleSquadPos[1])+abs(rectangleSquadPos[0])
	else:
		distanceX = abs(rectangleSquadPos[0]-rectangleSquadPos[1])
	if rectangleSquadPos[3]<0 and rectangleSquadPos[2]>0:
		distanceZ = abs(rectangleSquadPos[3])+abs(rectangleSquadPos[2])
	else:
		distanceZ = abs(rectangleSquadPos[2]-rectangleSquadPos[3])
	centerPositionOfSquad = Vector3((rectangleSquadPos[2]+rectangleSquadPos[3])/2, 2, (rectangleSquadPos[0]+rectangleSquadPos[1])/2)
	RenderingServer.instance_set_transform(rectangleSquad, Transform3D(
		Vector3(distanceZ,0,0),
		Vector3(0,1,0),
		Vector3(0,0,distanceX), 
		centerPositionOfSquad))
	rectangleSquadPos[0] = (rectangleSquadPos[0]+rectangleSquadPos[1])/2
	rectangleSquadPos[1] = (rectangleSquadPos[0]+rectangleSquadPos[1])/2
	rectangleSquadPos[2] = (rectangleSquadPos[2]+rectangleSquadPos[3])/2
	rectangleSquadPos[3] = (rectangleSquadPos[2]+rectangleSquadPos[3])/2

func moveMarker(newPosition:Vector3):
	squadAgent.target_position = newPosition
	allSquadPath.clear()
	allSquadPath = mapAndPath.getPath(centerPositionOfSquad,newPosition)
	var i = 1
	formationAngleToPath.clear()
	while (i<=allSquadPath.size()-1):
		formationAngleToPath.append(Vector2(allSquadPath[i-1].x,allSquadPath[i-1].z).angle_to_point(Vector2(allSquadPath[i].x,allSquadPath[i].z)))
		
		i+=1
	allSquadPath.remove_at(0)
	numberOfPathForEach.clear()
	for j in allChildMainMesh.size():
		numberOfPathForEach.append(allSquadPath.size())
		allPath[j].clear()
		pathComplete[j] = true

func findPathForOneUnit(nextPath, numberMesh, numberOfPath):
	allPath[numberMesh].clear()
	allPath[numberMesh] = mapAndPath.getPath(allChildMainMeshPosition[numberMesh].origin,
			Vector3(nextPath.x+formationPositions[numberMesh].rotated(formationAngleToPath[numberOfPath]).x,
			nextPath.y,
			nextPath.z + formationPositions[numberMesh].rotated(formationAngleToPath[numberOfPath]).y))
	currentPath[numberMesh] = allPath[numberMesh][0]
	allPath[numberMesh].remove_at(0)
	


func findPathForEachUnit(nextPath):
	var angleToNextPositionInRad = Vector2(centerPositionOfSquad.x,centerPositionOfSquad.z).angle_to_point(Vector2(nextPath.x,nextPath.z))
	var angleToNextPositionInDeg = snapped(remap(rad_to_deg(angleToNextPositionInRad),-180,180,0,360),1)
	var angleToPath = deg_to_rad(angleToNextPositionInDeg)
	allPath.clear()
	currentPath.clear()
	for i in allChildMainMesh.size():
		allPath.append(PackedVector3Array())
		allPath[i] = mapAndPath.getPath(allChildMainMeshPosition[i].origin,
			Vector3(nextPath.x+formationPositions[i].rotated(angleToPath).x,
			nextPath.y,
			nextPath.z+formationPositions[i].rotated(angleToPath).y)) 
		currentPath.append(allPath[i][0])
		allPath[i].remove_at(0)
	
		
func selectedTrue():
	for i in allChildSelectMesh:
		RenderingServer.instance_set_visible(i,true)

func selectedFalse():
	for i in allChildSelectMesh:
		RenderingServer.instance_set_visible(i,false)
		
func isInRange(firstPoint:Vector2,secondPoint:Vector2):
	for i in allChildMainMeshPosition:
		if (i.origin.x>firstPoint.x and i.origin.z<firstPoint.y and i.origin.x<secondPoint.x and i.origin.z>secondPoint.y):
			return true
	return false
			
	
