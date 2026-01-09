extends Node
class_name PCG_monitor

var base_grid: Array[int]
var monitor_position: Array[int]

var ring_monitor_frequency: int
var shield_monitor_frequency: int
var boots_monitor_frequency: int

var flat_position: Array[int]

func find_all_flat_position():
	for i in range(base_grid.size()):
		if base_grid[i] == 0:
			flat_position.append(i)

func generate_monitor_position():
	for i in range(ring_monitor_frequency):
		monitor_position.append(1)
	for i in range(shield_monitor_frequency):
		monitor_position.append(2)
	for i in range(boots_monitor_frequency):
		monitor_position.append(3)
	for i in range(flat_position.size()-ring_monitor_frequency-shield_monitor_frequency-boots_monitor_frequency):
		monitor_position.append(0)
	monitor_position.shuffle()
	for i in range(base_grid.size()):
		if !flat_position.has(i):
			monitor_position.insert(i,0)
	
func _init(base_grid: Array, ring_monitor_frequency: int, shield_monitor_frequency: int, boots_monitor_frequency: int):
	self.base_grid = base_grid
	self.ring_monitor_frequency = ring_monitor_frequency
	self.shield_monitor_frequency = shield_monitor_frequency
	self.boots_monitor_frequency = boots_monitor_frequency
