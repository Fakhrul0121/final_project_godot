extends Node
class_name PCG_enemy

var cell_size: int
var enemy_position: Array[int]

var bug_frequency: int
var monkey_frequency: int

func generate_enemy_position():
	for i in range(bug_frequency):
		enemy_position.append(1)
	for i in range(monkey_frequency):
		enemy_position.append(2)
	for i in range(cell_size-bug_frequency-monkey_frequency):
		enemy_position.append(0)
	enemy_position.shuffle()
	

func _init(cell_size: int, bug_frequency: int, monkey_frequency: int):
	self.cell_size = cell_size
	self.bug_frequency = bug_frequency
	self.monkey_frequency = monkey_frequency
