extends Button
@onready var entitys = $"../../Entitys"

var entityNode = preload("res://Nodes/UnitsSquad/SquadUnit.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_pressed():
	var instance = entityNode.instantiate()
	entitys.add_child(instance)
