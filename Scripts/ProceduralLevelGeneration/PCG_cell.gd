@tool
extends TileMap
class_name PCG_cell

@export var base_grid: Array
@export var enemy_arr: Array

@export var terrain: PCG_terrain
@export var figure: PCG_figure

@export_category("Terrain")

@export var is_top: bool

@export_group("generate terrain")
@export var terrain_size: int
@export var single_incline_frequency: int
@export var double_incline_frequency: int
@export var single_downcline_frequency: int
@export var double_downcline_frequency: int

#constraint violation
@export_group("constraint violation")
@export var end_height_constraint: int
@export var max_height_constraint: int
@export var min_height_constraint: int

#objective function
@export_group("objective function")
@export var preferred_speedup_value: int
@export var preferred_speeddown_value: int

## some helpful tips on figure
## id 5 = loop, id 6 = twister, id 7 = bridge
## id 8 = spring, id 9 = ramps (up), id 10 = ramps (down)
## the rest is customize

@export_category("Figure")
@export var figures: Array[Array]

@export_category("Obstacle")
@export_group("Spike")
@export var spike_position: Array
@export var spike_frequency: int
@export var hidden_spike_frequency: int
@export_group("Enemy")
@export var enemy_position: Array
@export var buzz_frequency: int
@export var monkey_frequency: int

@export_category("Monitor")
@export var monitor_position: Array
@export var ring_monitor_frequency: int
@export var shield_monitor_frequency: int
@export var boots_monitor_frequency: int

#items
var enemy: PCG_enemy
var spike: PCG_spike
var monitor: PCG_monitor

@export_category("try it")
@export_tool_button("generate cell")
var generate_cell: Callable = func():
	generate_cell_backend()
	generate_base_frontend()

@export_category("testing only")
@export_tool_button("test add pattern")
var test_a_p: Callable = func():
	var pit_3 = tile_set.get_pattern(14)
	set_pattern(0, Vector2i(0,0), pit_3)
	var flat = tile_set.get_pattern(16)
	set_pattern(0, Vector2i(8,-4), flat)
	
	pass

@export_tool_button("clear cells")
var clear_c: Callable = func():
	clear_layer(0)
	base_grid = []
	terrain = null
	figure = null

##Generate frontend
func generate_base_frontend():
	## set terrain
	var flat = tile_set.get_pattern(33)
	var flat_top = tile_set.get_pattern(34)
	var downcline = tile_set.get_pattern(29)
	var downcline_top = tile_set.get_pattern(36)
	var upcline = tile_set.get_pattern(28)
	var upcline_top = tile_set.get_pattern(35)
	var double_upcline = tile_set.get_pattern(31)
	var double_upcline_top = tile_set.get_pattern(38)
	var double_downcline = tile_set.get_pattern(30)
	var double_downcline_top = tile_set.get_pattern(37)
	## set figure
	var ramps_up = tile_set.get_pattern(24)
	var ramps_up_top = tile_set.get_pattern(44)
	var ramps_down = tile_set.get_pattern(26)
	var ramps_down_top = tile_set.get_pattern(43)
	var sine = tile_set.get_pattern(7)
	var bridge = tile_set.get_pattern(8)
	var twister = tile_set.get_pattern(9)
	var loops = tile_set.get_pattern(47)
	var loops_top = tile_set.get_pattern(40)
	var pit_1 = tile_set.get_pattern(39)
	var pit_2 = tile_set.get_pattern(41)
	var ramps_up_unique = tile_set.get_pattern(42)
	var pit_3 = tile_set.get_pattern(46)
	var set_piece = tile_set.get_pattern(15)
	var front_spring = tile_set.get_pattern(25)
	var front_spring_top = tile_set.get_pattern(45)
	
	var current_height = 0
	var current_length = 0
	for i in base_grid:
		if i == 0: #flat
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height), flat_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height), flat)
		elif i == 1: #up
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height-2), upcline_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height-2), upcline)
			current_height -= 2
		elif i == -1: #down
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height), downcline_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height), downcline)
			
			current_height += 2
		elif i == 2: #double up
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height-4), double_upcline_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height-4), double_upcline)
			current_height -= 4
		elif i == -2: #double down
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height), double_downcline_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height), double_downcline)
			
			current_height += 4
		elif i == 6: #loops
			set_pattern(0, Vector2i(current_length,current_height-12), loops)
			
			
		elif i == 7: #twister
			set_pattern(0, Vector2i(current_length,current_height), twister)
			current_length += 16
		elif i == 8: #bridge with fish
			set_pattern(0, Vector2i(current_length,current_height), bridge)
			current_length += 8
		elif i == 9: #ramps up
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height-4), ramps_up_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height-4), ramps_up)
			
			current_height -= 4
		elif i == 10: #ramps down
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height), ramps_down_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height), ramps_down)
			
			current_height += 4
		elif i == 11:
			if (is_top):
				set_pattern(0, Vector2i(current_length,current_height), front_spring_top)
			else:
				set_pattern(0, Vector2i(current_length,current_height), front_spring)
			
			current_height += 2
		#custom figure
		elif i == 21: #pit_1
			set_pattern(0, Vector2i(current_length,current_height-2), pit_1)
			current_height -= 2
			current_length += 8
		elif i == 22: #pit_2
			set_pattern(0, Vector2i(current_length,current_height-6), pit_2)
			current_height -= 6
			current_length += 8*3
		elif i == 23: #ramps_up_unique
			set_pattern(0, Vector2i(current_length,current_height-11), ramps_up_unique)
			current_height -= 10
		elif i == 24: #pit_3
			set_pattern(0, Vector2i(current_length,current_height), pit_3)
			current_height -= 4
		current_length += 8


##Generate backend
func generate_cell_backend():
	set_terrain()
	set_figure()
	generate_base()
	#generate_enemy()
	#generate_spike()
	#generate_monitor()

func generate_base():
	var base_grid_with_other_variable = terrain.generate_terrain()
	base_grid = base_grid_with_other_variable[0]
	figure.set_terrain(base_grid)
	
	base_grid = figure.generate_figure()
	print("figure.terrain_array ", figure.terrain_array)

func generate_enemy():
	enemy = PCG_enemy.new(base_grid.size(),buzz_frequency,monkey_frequency)
	enemy.generate_enemy_position()
	enemy_position = enemy.enemy_position

func generate_spike():
	spike = PCG_spike.new(base_grid,spike_frequency,hidden_spike_frequency)
	spike.generate_spike_position()
	spike_position = spike.spike_position

func generate_monitor():
	monitor = PCG_monitor.new(base_grid,ring_monitor_frequency,shield_monitor_frequency,boots_monitor_frequency)
	monitor.generate_monitor_position()
	monitor_position = monitor.monitor_position

func set_terrain():
	terrain = PCG_terrain.new()
	terrain.set_generate_terrain_variable(terrain_size, single_incline_frequency, double_incline_frequency, single_downcline_frequency, double_downcline_frequency)
	terrain.set_generate_objective_function(preferred_speedup_value, preferred_speeddown_value)
	terrain.set_constraint_violation_variable(end_height_constraint, max_height_constraint, min_height_constraint)

func set_figure():
	figure = PCG_figure.new()
	print(figures)
	figure.max_height_constraint = self.max_height_constraint
	figure.min_height_constraint = self.min_height_constraint
	for figure_item in figures:
		figure.figures.append(Figure.new(figure_item[0],figure_item[1],figure_item[2]))
	
