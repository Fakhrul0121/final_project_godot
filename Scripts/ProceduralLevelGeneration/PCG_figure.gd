@tool
extends Node

class_name PCG_figure

var terrain_array: Array

var max_height_constraint: int
var min_height_constraint: int

## some helpful tips on figure
## id 5 = loop, id 6 = twister, id 7 = bridge
## id 8 = spring, id 9 = ramps (up), id 10 = ramps (down)
## the rest is customize

@export var figures: Array[Figure]
@export var position: Array[int]

@export_tool_button("test other stuff")
var c: Callable = func():
	for i in []:
		print("it didn't")
	print("did it worked?")
	#print(range(12))
	#print([0,1,2].size())
	#print(range(4,2).size())
	#var arr = [0,1,2,5,4]
	#arr.insert(1,9)
	#print(arr)

@export_tool_button("test PCG")
var test_figure: Callable = func():
	set_for_test()
	generate_figure()
	#print(terrain_array)
	clear_testing_data()

func set_terrain(terrain: Array):
	#print("terrain ",terrain)
	terrain_array = terrain

func set_for_test():
	#Figures
	figures.append(Figure.new(10, [2, 2], [1,1]))
	figures.append(Figure.new(11, [1,1], [2,1]))
	figures.append(Figure.new(12, [1, 0], [1,0]))
	figures.append(Figure.new(9, [2,1], [1,0]))
	#Terrain
	terrain_array = [2,2,1,1,2,1,1,0,1,0]

func clear_testing_data():
	figures = []
	terrain_array = []
	

func generate_figure():
	for figure in figures:
		iteration_algorithm(figure)
	return terrain_array

func iteration_algorithm(active_figures: Figure):
	var fitness_arr = []
	#print("terrain_array ", terrain_array)
	for i in range(terrain_array.size()+1):
		#print("position: ",i)
		terrain_array.insert(i,active_figures.id_figure)
		if (constraint_violation(terrain_array) > 0):
			fitness_arr.append(0)
		else:
			fitness_arr.append(fitness(i, active_figures))
		terrain_array.remove_at(i)
	#print(fitness_arr)
	terrain_array.insert(select_position(fitness_arr),active_figures.id_figure)
	pass

func select_position(fitness_arr: Array):
	var highest_fitness = fitness_arr.max()
	var position = fitness_arr.find(highest_fitness)
	return position

func fitness(position: int, active_figures: Figure):
	var fitness: int = (active_figures.back_preference.size() + active_figures.front_preference.size()) * 2
	#print("initial fitness ", fitness)
	if active_figures.front_preference != []:
		for i in range(1, active_figures.front_preference.size()+1):
			#print("i+position front ", i+position)
			#print("terrain_array.size() ", terrain_array.size()-1)
			if i+position >= terrain_array.size():
				fitness -= 2
				#print("pass front")
				#print("fitness front ", fitness)
			else:
				var current_preference_variable = active_figures.front_preference[i-1]
				var current_terrain_variable = terrain_array[position+i]
				#print("current_preference_variable ",current_preference_variable," current_terrain_variable ",current_terrain_variable)
				fitness -= fitness_calculation(current_terrain_variable, current_preference_variable)
				#print("fitness front ", fitness)
	if active_figures.back_preference != []:
		for i in range(-1, -active_figures.back_preference.size()-1, -1):
			#print("i+position back ", i+position)
			if i+position < 0:
				fitness -= 2
				#print("pass back")
				#print("fitness back ", fitness)
			else:
				var current_preference_variable = active_figures.back_preference[i]
				var current_terrain_variable = terrain_array[position+i]
				#print("current_preference_variable ",current_preference_variable," current_terrain_variable ",current_terrain_variable)
				fitness -= fitness_calculation(current_terrain_variable, current_preference_variable)
				#print("fitness back ", fitness)
	return fitness

func fitness_calculation(current_preference_variable: int, current_terrain_variable: int):
	var fitness
	if current_preference_variable < current_terrain_variable:
		fitness = range(current_preference_variable, current_terrain_variable).size()
	else:
		fitness = range(current_terrain_variable, current_preference_variable).size()
	return min(2,fitness)
	#return fitness

func constraint_violation(arr: Array):
	var constraint_value = 0
	#setup
	var end_height = 0
	var max_height = 0
	var min_height = 0
	var current_height = 0
	print("array ", arr)
	for i in arr:
		match i:
			-2, -1, 0, 1, 2:
				current_height += i
				max_height = max(max_height, current_height)
				min_height = min(min_height, current_height)
			6, 7, 8:
				current_height += 0
			9:
				current_height += 2
				max_height = max(max_height, current_height)
			10:
				current_height -= 2
				min_height = min(min_height, current_height)
			11:
				current_height -= 1
				min_height = min(min_height, current_height)
			21:
				max_height = max(max_height, current_height+1)
				min_height = min(min_height, current_height-3)
				current_height += 1
			22:
				max_height = max(max_height, current_height+3)
				min_height = min(min_height, current_height-5)
				current_height += 3
			23:
				current_height += 5
				max_height = max(max_height, current_height)
			24:
				max_height = max(max_height, current_height+2)
				min_height = min(min_height, current_height-2)
				current_height += 2
	end_height = current_height
	#print("arr ", arr, " end_height ", end_height)
	var max_height_constraint_value = abs(min(0,max_height_constraint-max_height))
	var min_height_constraint_value = max(0, min_height_constraint-min_height)
	constraint_value +=  max_height_constraint_value + min_height_constraint_value
	print([constraint_value, max_height_constraint_value, min_height_constraint_value])
	return constraint_value
