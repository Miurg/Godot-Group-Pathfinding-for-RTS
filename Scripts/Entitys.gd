extends Node

@onready var workDistributor = $".."
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var entitysSelected = []
func findSelected(firstPoint:Vector2,secondPoint:Vector2):
	for i in entitysSelected:
		i.selectedFalse()
	var entitys = get_children()
	entitysSelected.clear()
	for i in entitys:
		if i.isInRange(firstPoint,secondPoint):
			i.selectedTrue()
			entitysSelected.push_front(i)
	workDistributor.selectedEntitys.clear()
	workDistributor.selectedEntitys.append_array(entitysSelected)
	
