extends Node3D

@onready var workDistributor = $"../.."
var oneUnitNode = preload("res://OneUnit.tscn")
var allChildMainMesh = []
var allChildSelectMesh = []
var allChildMainMeshPosition = []
var allChildSelectMeshPosition = []
var capsuleMesh = CapsuleMesh.new()
var torusMesh = load("res://Select.tres")

var currentSquadPosition = Vector3(10,2,30)
var allSquadPath = []
var currentPath = []
var allPath = []
var numberOfPathForEach = []
var rows = 10
var columns = 30


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in rows:
		for j in columns:
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
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i in allChildMainMesh.size():
		numberOfPathForEach.append(0)
	var j = 0
	var k = 0
	for i in allChildMainMesh.size():
		if j == rows:
			k+=1
			j=0
		else: j+=1
		localPositionOfUnit.append([])
		localPositionOfUnit[i].append(k)
		localPositionOfUnit[i].append(j)
	findPathForEachUnit(allChildMainMeshPosition[allChildMainMesh.size()/2].origin)
	
	
func _physics_process(delta):
	#var numberMeshWhoReachedCurrentSquadPath = 0
	if currentPath.size()==0:
		return
	for i in allChildMainMesh.size():
		if allChildMainMeshPosition[i].origin==currentPath[i] and !allPath[i].is_empty():
			currentPath[i] = allPath[i][0]
			allPath[i].remove_at(0)
		elif allChildMainMeshPosition[i].origin==currentPath[i] and allPath[i].is_empty():
			numberOfPathForEach[i]-=1
			if numberOfPathForEach[i]>0:
				findPathForOneUnit(allSquadPath[allSquadPath.size()-numberOfPathForEach[i]], i)
				#numberMeshWhoReachedCurrentSquadPath+=1
		if allChildMainMeshPosition[i].origin!=currentPath[i]:
			allChildMainMeshPosition[i] = Transform3D(Basis(),
				allChildMainMeshPosition[i].origin.move_toward(currentPath[i], delta * 10))
			RenderingServer.instance_set_transform(allChildMainMesh[i], allChildMainMeshPosition[i])
			RenderingServer.instance_set_transform(allChildSelectMesh[i], 
			Transform3D(Basis(),Vector3(allChildMainMeshPosition[i].origin.x,
			allChildMainMeshPosition[i].origin.y-1,
			allChildMainMeshPosition[i].origin.z)))

	#if numberMeshWhoReachedCurrentSquadPath == allChildMainMesh.size() and !allSquadPath.is_empty():
		#currentSquadPath = allSquadPath[0]
		#allSquadPath.remove_at(0)
		#findPathForEachUnit(currentSquadPath)


	
func selectedTrue():
	for i in allChildSelectMesh:
		RenderingServer.instance_set_visible(i,true)

func selectedFalse():
	for i in allChildSelectMesh:
		RenderingServer.instance_set_visible(i,false)

func moveMarker(newPosition:Vector3):
	allSquadPath.clear()
	allSquadPath = workDistributor.getPath(allChildMainMeshPosition[allChildMainMesh.size()/2].origin,newPosition)
	#allSquadPath.remove_at(0)
	numberOfPathForEach.clear()
	for i in allChildMainMesh.size():
		numberOfPathForEach.append(allSquadPath.size())
	#currentSquadPath = allSquadPath[0]
	#allSquadPath.remove_at(0)
	#findPathForEachUnit(allChildMainMeshPosition[0].origin)
	

var localPositionOfUnit = [[]]

func findPathForOneUnit(nextPath, numberMesh):
	allPath[numberMesh].clear()
	allPath[numberMesh] = workDistributor.getPath(allChildMainMeshPosition[numberMesh].origin,
			Vector3(nextPath.x+localPositionOfUnit[numberMesh][0],nextPath.y,nextPath.z+localPositionOfUnit[numberMesh][1])) 
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
