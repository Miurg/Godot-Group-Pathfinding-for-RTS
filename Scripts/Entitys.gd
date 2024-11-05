extends Node

@onready var workDistributor = $".."
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
var entitysSelected = []
func findSelected(firstPoint:Vector2,secondPoint:Vector2):
	for i in entitysSelected:
		i.selectedFalse()
	var entitys = get_children()
	entitysSelected.clear()
	for i in entitys:
		if (i.position.x>firstPoint.x and i.position.z<firstPoint.y and i.position.x<secondPoint.x and i.position.z>secondPoint.y):
			entitysSelected.push_front(i)
			i.selectedTrue()
	workDistributor.selectedEntitys.clear()
	workDistributor.selectedEntitys.append_array(entitysSelected)
	
