extends Node
class_name PCG_spike

var base_grid: Array[int]
var spike_position: Array[int]

var normal_spike_frequency: int
var hidden_spike_frequency: int

var flat_position: Array[int]

func find_all_flat_position():
	for i in range(base_grid.size()):
		if base_grid[i] == 0:
			flat_position.append(i)

func generate_spike_position():
	for i in range(normal_spike_frequency):
		spike_position.append(1)
	for i in range(hidden_spike_frequency):
		spike_position.append(2)
	for i in range(flat_position.size()-normal_spike_frequency-hidden_spike_frequency):
		spike_position.append(0)
	spike_position.shuffle()
	for i in range(base_grid.size()):
		if !flat_position.has(i):
			spike_position.insert(i,0)

func _init(base_grid: Array[int], normal_spike_frequency: int, hidden_spike_frequency: int):
	self.base_grid = base_grid
	self.normal_spike_frequency = normal_spike_frequency
	self.hidden_spike_frequency = hidden_spike_frequency
