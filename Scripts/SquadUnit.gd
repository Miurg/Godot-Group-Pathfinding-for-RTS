extends Node3D

@onready var workDistributor = $"../.."
var oneUnitNode = preload("res://OneUnit.tscn")


var allChildMainMesh = []
var allChildSelectMesh = []
var allChildMainMeshPosition = []
var allChildSelectMeshPosition = []
var allChildAgents = []
var capsuleMesh = CapsuleMesh.new()
var torusMesh = load("res://Select.tres")

var allSquadPath = []
var currentPath = []
var allPath = []

var numberOfPathForEach = []
var localPositionOfUnit = [[]]
var centerPositionOfSquad = Vector3(0,0,0)

#z> = 0, z< = 1, x> = 2, x< = 3
var rectangleSquadPos = [0,0,0,0]
var rectangleSquad
var rectangleMesh = load("res://Box.tres")

@onready var squadAgent = $NavigationAgent3D

var y = 30
var x = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in y:
		for j in x:
			var instanceMain = RenderingServer.instance_create()
			var instanceSelect = RenderingServer.instance_create()
			var scenario = get_world_3d().scenario
			RenderingServer.instance_set_scenario(instanceMain, scenario)
			RenderingServer.instance_set_scenario(instanceSelect, scenario)
			
			RenderingServer.instance_set_base(instanceMain, capsuleMesh)
			RenderingServer.instance_set_base(instanceSelect, torusMesh)
			
			var xformMain = Transform3D(Basis(), Vector3(i+2, 2, j+2))
			var xformSelect = Transform3D(Basis(), Vector3(i+2, 19, j+2))
			
			RenderingServer.instance_set_transform(instanceMain, xformMain)
			RenderingServer.instance_set_transform(instanceSelect, xformSelect)
			
			allChildMainMeshPosition.append(xformMain)
			allChildSelectMeshPosition.append(xformSelect)
			
			RenderingServer.instance_set_visible(instanceSelect,false)
			
			allChildMainMesh.append(instanceMain)
			allChildSelectMesh.append(instanceSelect)
			
			allChildAgents.append(NavigationServer3D.agent_create())
			
		
	var j = -1
	var k = 0
	for i in allChildMainMesh.size():
		numberOfPathForEach.append(0)
		if j == y-1:
			k+=1
			j=0
		else: j+=1
		localPositionOfUnit.append([])
		localPositionOfUnit[i].append(k)
		localPositionOfUnit[i].append(j)
		
		
	rectangleSquad = RenderingServer.instance_create()
	RenderingServer.instance_set_scenario(rectangleSquad, get_world_3d().scenario)
	RenderingServer.instance_set_base(rectangleSquad, rectangleMesh)
	RenderingServer.instance_set_transform(rectangleSquad, Transform3D(Basis(), Vector3(5, 2, 5)))
	rectangleProcess()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	findPathForEachUnit(centerPositionOfSquad)
	

	

func _process(delta):
	squadAgent.get_next_path_position()
	if currentPath.size()==0:
		return
	checkAndMove(delta)
	rectangleProcess()
	global_position = centerPositionOfSquad



func checkAndMove(delta):
	for i in allChildMainMesh.size():
		if allChildMainMeshPosition[i].origin==currentPath[i] and !allPath[i].is_empty():
			currentPath[i] = allPath[i][0]
			allPath[i].remove_at(0)
		elif allChildMainMeshPosition[i].origin==currentPath[i] and allPath[i].is_empty():
			numberOfPathForEach[i]-=1
			if numberOfPathForEach[i]>0:
				findPathForOneUnit(allSquadPath[allSquadPath.size()-numberOfPathForEach[i]], i)
		if allChildMainMeshPosition[i].origin!=currentPath[i]:
			allChildMainMeshPosition[i] = Transform3D(Basis(),
				allChildMainMeshPosition[i].origin.move_toward(currentPath[i], delta * 10))
			RenderingServer.instance_set_transform(allChildMainMesh[i], allChildMainMeshPosition[i])
			RenderingServer.instance_set_transform(allChildSelectMesh[i], 
			Transform3D(Basis(),Vector3(allChildMainMeshPosition[i].origin.x,
			allChildMainMeshPosition[i].origin.y-1,
			allChildMainMeshPosition[i].origin.z)))

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
	allSquadPath = workDistributor.getPath(centerPositionOfSquad,newPosition)
	#allSquadPath.remove_at(0)
	numberOfPathForEach.clear()
	for i in allChildMainMesh.size():
		numberOfPathForEach.append(allSquadPath.size())
		allPath[i].clear()
		#currentPath[i].clear()
	#currentSquadPath = allSquadPath[0]
	#allSquadPath.remove_at(0)
	#findPathForEachUnit(allChildMainMeshPosition[0].origin)
	

func findPathForOneUnit(nextPath, numberMesh):
	allPath[numberMesh].clear()
	allPath[numberMesh] = workDistributor.getPath(allChildMainMeshPosition[numberMesh].origin,
			Vector3(nextPath.x+localPositionOfUnit[numberMesh][0]-x/2,nextPath.y,nextPath.z+localPositionOfUnit[numberMesh][1]-y/2)) 
	currentPath.append(allPath[numberMesh][0])
	allPath[numberMesh].remove_at(0)
	


func findPathForEachUnit(nextPath):
	allPath.clear()
	currentPath.clear()
	for i in allChildMainMesh.size():
		allPath.append([])
		allPath[i] = workDistributor.getPath(allChildMainMeshPosition[i].origin,
			Vector3(nextPath.x+localPositionOfUnit[i][0],nextPath.y,nextPath.z+localPositionOfUnit[i][1])) 
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
			
	
