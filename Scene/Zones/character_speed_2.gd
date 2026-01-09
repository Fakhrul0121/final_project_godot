extends Label

@export var character: CharacterBody2D

func _process(delta: float) -> void:
	text = str(character.movement.y)
	pass
