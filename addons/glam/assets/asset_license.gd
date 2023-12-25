@tool
extends Resource

@export var identifier: String


func _init(identifier := ""):
	if not identifier.is_empty():
		self.identifier = identifier
