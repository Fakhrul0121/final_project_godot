extends Node
class_name Figure

var id_figure: int
var back_preference: Array
var front_preference: Array
#func new():
#	pass

func _init(id_figure: int, back_preference: Array, front_preference: Array):
	self.id_figure = id_figure
	self.back_preference = back_preference
	self.front_preference = front_preference

func print_var():
	print("id ",id_figure)
	print("back_preference ",back_preference)
	print("front_preference ",front_preference)
