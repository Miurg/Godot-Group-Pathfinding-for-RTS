extends Node3D

@onready var workDistributor = $"../.."
var oneUnitNode = preload("res://OneUnit.tscn")
var allChilMainMesh = []
var allChildSelectMesh = []
var allChildMainMeshPosition = []
var allChildSelectMeshPosition = []
var capsuleMesh = CapsuleMesh.new()
var torusMesh = load("res://Select.tres")

var currentSquadPath = Vector3(10,2,30)
var allSquadPath = []
var currentPath = []
var allPath = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in 10:
		for j in 3:
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
			
			allChilMainMesh.append(instanceMain)
			allChildSelectMesh.append(instanceSelect)
	await get_tree().physics_frame
	await get_tree().physics_frame
	findPathForEachUnit(currentSquadPath)
	
func _physics_process(delta):
	var numberMeshWhoReachedCurrentSquadPath = 0
	if currentPath.size()==0:
		return
	for i in allChilMainMesh.size():
		if allChildMainMeshPosition[i].origin==currentPath[i] and !allPath[i].is_empty():
			currentPath[i] = allPath[i][0]
			allPath[i].remove_at(0)
		elif allChildMainMeshPosition[i].origin==currentPath[i] and allPath[i].is_empty():
				numberMeshWhoReachedCurrentSquadPath+=1
		if allChildMainMeshPosition[i].origin!=currentPath[i]:
			allChildMainMeshPosition[i] = Transform3D(Basis(),allChildMainMeshPosition[i].origin.move_toward(currentPath[i], delta * 10))
			RenderingServer.instance_set_transform(allChilMainMesh[i], allChildMainMeshPosition[i])
			RenderingServer.instance_set_transform(allChildSelectMesh[i], 
			Transform3D(Basis(),Vector3(allChildMainMeshPosition[i].origin.x,
			allChildMainMeshPosition[i].origin.y-1,
			allChildMainMeshPosition[i].origin.z)))
	if numberMeshWhoReachedCurrentSquadPath == allChilMainMesh.size() and !allSquadPath.is_empty():
		currentSquadPath = allSquadPath[0]
		allSquadPath.remove_at(0)
		findPathForEachUnit(currentSquadPath)
				
	pass


	
func selectedTrue():
	for i in allChildSelectMesh:
		RenderingServer.instance_set_visible(i,true)

func selectedFalse():
	for i in allChildSelectMesh:
		RenderingServer.instance_set_visible(i,false)

func moveMarker(newPosition:Vector3):
	allSquadPath.clear()
	allSquadPath = workDistributor.getPath(currentSquadPath,newPosition)
	allSquadPath.remove_at(0)
	currentSquadPath = allSquadPath[0]
	allSquadPath.remove_at(0)
	findPathForEachUnit(currentSquadPath)
	
func findPathForEachUnit(nextPath):
	allPath.clear()
	currentPath.clear()
	var j = 0
	var k = 0
	for i in allChilMainMesh.size():
		if j == 3:
			k+=1
			j=0
		else: j+=1
		allPath.append([])
		allPath[i] = workDistributor.getPath(allChildMainMeshPosition[i].origin,Vector3(nextPath.x+k,nextPath.y,nextPath.z+j)) 
		currentPath.append(allPath[i][0])
		allPath[i].remove_at(0)
	print_debug(nextPath)
	print_debug(allPath[0])
	print_debug(allPath[1])
