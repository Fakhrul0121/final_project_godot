@tool
extends Node2D
class_name PCG_terrain

const POPULATION_SIZE = 100
const GENERATIONS = 10
const TOP_K = 5

#generate terrain
@export_category("generate terrain")
@export var terrain_size: int
@export var single_incline_frequency: int
@export var double_incline_frequency: int
@export var single_downcline_frequency: int
@export var double_downcline_frequency: int

#constraint violation
@export_category("constraint violation")
@export var end_height_constraint: int
@export var max_height_constraint: int
@export var min_height_constraint: int

#objective function
@export_category("objective function")
@export var preferred_speedup_value: int
@export var preferred_speeddown_value: int

@export_tool_button("test generate") var c: Callable = func(): generate_terrain()

func set_generate_terrain_variable(terrain_size: int, single_incline_frequency: int, double_incline_frequency: int, single_downcline_frequency: int, double_downcline_frequency: int):
	self.terrain_size = terrain_size
	self.single_incline_frequency = single_incline_frequency
	self.double_incline_frequency = double_incline_frequency
	self.single_downcline_frequency = single_downcline_frequency
	self.double_downcline_frequency = double_downcline_frequency

func set_constraint_violation_variable(end_height_constraint: int, max_height_constraint: int, min_height_constraint: int):
	self.end_height_constraint = end_height_constraint
	self.max_height_constraint = max_height_constraint
	self.min_height_constraint = min_height_constraint

func set_generate_objective_function(preferred_speedup_value: int, preferred_speeddown_value: int):
	self.preferred_speedup_value = preferred_speedup_value
	self.preferred_speeddown_value = preferred_speeddown_value

func generate_individual():
	return generate_individual_old()
	#return generate_individual_new()

func generate_individual_new():
	var main_arr = []
	for i in range(terrain_size):
		main_arr.append(randi_range(-2,2))
	return main_arr

func generate_individual_old():
	var main_arr = []
	#print("single incline ", single_incline_frequency)
	#print("double incline ", double_incline_frequency)
	#print("single downcline ", single_downcline_frequency)
	#print("double downcline ", double_downcline_frequency)
	for i in range(terrain_size-single_incline_frequency-double_incline_frequency-single_downcline_frequency-double_downcline_frequency):
		main_arr.append(0)
	for i in range(single_incline_frequency):
		main_arr.append(1)
	for i in range(double_incline_frequency):
		main_arr.append(2)
	for i in range(single_downcline_frequency):
		main_arr.append(-1)
	for i in range(double_downcline_frequency):
		main_arr.append(-2)
	#shuffle
	#print("before shuffle", main_arr)
	main_arr.shuffle()
	#print("after shuffle", main_arr)
	return main_arr



func constraint_violation(arr: Array):
	var constraint_value = 0
	#setup
	var end_height = 0
	var max_height = 0
	var min_height = 0
	var current_height = 0
	for i in arr:
		current_height += i
		max_height = max(max_height, current_height)
		min_height = min(min_height, current_height)
	end_height = current_height
	#print("arr ", arr, " end_height ", end_height)
	var end_height_constraint_value = abs(end_height_constraint-end_height)
	var max_height_constraint_value =  abs(min(0,max_height_constraint-max_height))
	var min_height_constraint_value = max(0, min_height_constraint-min_height)
	constraint_value += end_height_constraint_value
	constraint_value +=  max_height_constraint_value + min_height_constraint_value
	print([constraint_value, end_height_constraint_value, max_height_constraint_value, min_height_constraint_value])
	return [constraint_value, end_height_constraint_value, max_height_constraint_value, min_height_constraint_value]

func objective_function(arr: Array):
	#print(arr)
	var fitness = preferred_speedup_value + abs(preferred_speeddown_value)
	var speedup_value = 0
	var speeddown_value = 0
	var combo = 1
	for i in range(arr.size()):
		if combo > 1 and arr[i] != 0: #if iteration is combo and current data is not flat
			if arr[i] > 0 and arr[i-1] < 0: #reset combo for downcline to incline
				combo = 1
			elif arr[i] < 0 and arr[i-1] > 0: #reset combo for downcline to incline
				combo = 1
		if arr[i] > 0: # if upcline
			speedup_value += arr[i] * combo
			combo += 1 # increment combo
		elif arr[i] < 0: # if downcline
			speeddown_value += arr[i] * combo
			combo += 1 # increment combo
		else: # reset combo
			combo = 1
	#preferred
	#print("speedup_value ", speedup_value)
	#print("speeddown_value ", speeddown_value)
	var selisih_speedup = abs(preferred_speedup_value - speedup_value)
	var selisih_speeddown = abs(preferred_speeddown_value - speeddown_value)
	fitness -= selisih_speeddown + selisih_speedup
	#print(fitness)
	return [fitness, selisih_speedup, selisih_speeddown]

func initialize_population():
	var population: Array = []
	for i in range(POPULATION_SIZE):
		var individual = generate_individual()
		population.append(individual)
	return population

func selection(population: Array, fitness_values: Array, is_feasible: bool):
	var sorted_pop = population.duplicate()
	sorted_pop.sort_custom(func(a, b): return fitness_values[population.find(a)] > fitness_values[population.find(b)])
	#fitness
	var fitness = []
	var selected = sorted_pop.slice(0, TOP_K)
	#print("population ", population)
	for ind in selected:
			fitness.append(objective_function(ind)[0])
	return [selected, fitness]

#func index_combo(individual):

func crossover(pop: Array, top_pop: Array, is_feasible: bool):
	var new_population = []
	#if is_feasible:
	for ind in pop:
		var child = []
		var top_parent = top_pop[randi_range(0, top_pop.size()-1)]
		var top_parent_first_index = randi_range(0, (terrain_size*3)/6)
		var top_parent_last_index = randi_range(top_parent_first_index+1, terrain_size-1)
		var top_parent_chromosome = top_parent.slice(top_parent_first_index, top_parent_last_index)
		var pop_parent_range = terrain_size - top_parent_chromosome.size()
		var pop_parent_first_index = randi_range(0,(terrain_size-pop_parent_range)-1)
		var pop_parent_last_index = pop_parent_first_index + pop_parent_range
		var pop_parent_chromosome = ind.slice(pop_parent_first_index, pop_parent_last_index)
		var pop_parent_chromosome_1 = pop_parent_chromosome.slice(0,pop_parent_chromosome.size()/2)
		var pop_parent_chromosome_2 = pop_parent_chromosome.slice(pop_parent_chromosome.size()/2,pop_parent_chromosome.size())
		child.append_array(pop_parent_chromosome_1)
		child.append_array(top_parent_chromosome)
		child.append_array(pop_parent_chromosome_2)
		new_population.append(child)
		#print("child size ", child.size())
	return new_population

# Mutation function
func mutate(ind: Array):
	#var index = randi_range(0, terrain_size-1)
	var flat_pos = []
	var single_incline_pos = []
	var single_downcline_pos = []
	var double_incline_pos = []
	var double_downcline_pos = []
	var  i = 0
	for item in ind:
		if item == 0:
			flat_pos.append(i)
		elif item == 1:
			single_incline_pos.append(i)
		elif item == -1:
			single_downcline_pos.append(i)
		elif item == 2:
			double_incline_pos.append(i)
		elif item == -2:
			double_downcline_pos.append(i)
		i += 1
	i = 0
	
	var flat_difference = flat_pos.size() - (terrain_size - single_incline_frequency - single_downcline_frequency - double_incline_frequency - double_downcline_frequency)
	var single_incline_difference = single_incline_pos.size() - single_incline_frequency
	var single_downcline_difference = single_downcline_pos.size() - single_downcline_frequency
	var double_incline_difference = double_incline_pos.size() - double_incline_frequency
	var double_downcline_difference = double_downcline_pos.size() - double_downcline_frequency
	
	var choosen_pos = []
	while flat_difference > 0:
		choosen_pos.append(flat_pos.pop_at(randi() % flat_pos.size()))
		flat_difference -= 1
	while single_incline_difference > 0:
		choosen_pos.append(single_incline_pos.pop_at(randi() % single_incline_pos.size()))
		single_incline_difference -= 1
	while single_downcline_difference > 0:
		choosen_pos.append(single_downcline_pos.pop_at(randi() % single_downcline_pos.size()))
		single_downcline_difference -= 1
	while double_incline_difference > 0:
		choosen_pos.append(double_incline_pos.pop_at(randi() % double_incline_pos.size()))
		double_incline_difference -= 1
	while double_downcline_difference > 0:
		choosen_pos.append(double_downcline_pos.pop_at(randi() % double_downcline_pos.size()))
		double_downcline_difference -= 1
	
	while flat_difference < 0:
		flat_pos.append(choosen_pos.pop_at(randi() % choosen_pos.size()))
		flat_difference += 1
	while single_incline_difference < 0:
		single_incline_pos.append(choosen_pos.pop_at(randi() % choosen_pos.size()))
		single_incline_difference += 1
	while single_downcline_difference < 0:
		single_downcline_pos.append(choosen_pos.pop_at(randi() % choosen_pos.size()))
		single_downcline_difference += 1
	while double_incline_difference < 0:
		double_incline_pos.append(choosen_pos.pop_at(randi() % choosen_pos.size()))
		double_incline_difference += 1
	while double_downcline_difference < 0:
		double_downcline_pos.append(choosen_pos.pop_at(randi() % choosen_pos.size()))
		double_downcline_difference += 1

	ind = []
	for pos in range(terrain_size+1):
		if flat_pos.has(pos):
			ind.append(0)
		elif single_incline_pos.has(pos):
			ind.append(1)
		elif single_downcline_pos.has(pos):
			ind.append(-1)
		elif double_incline_pos.has(pos):
			ind.append(2)
		elif double_downcline_pos.has(pos):
			ind.append(-2)
	
	return ind
	
# Main Genetic Algorithm with FI-2Pop and Gene Pool Recombination
func generate_terrain():
	var feasible_pop = []
	var infeasible_pop = []
	for i in range(POPULATION_SIZE):
		var individual = generate_individual()
		#print("constraint_violation(individual) ", individual, " ", constraint_violation(individual))
		if constraint_violation(individual)[0] <= 0:
			feasible_pop.append(individual)
		else:
			infeasible_pop.append(individual)
	var top_ind = []
	var top_ind_fitness = []
	#fitness calculation
	var feasible_fitness = []
	var infeasible_fitness = []
		
	#print("feasible_pop ",feasible_pop.size())
	#print("infeasible_pop ",infeasible_pop.size())
	for ind in feasible_pop:
		feasible_fitness.append(objective_function(ind)[0])
	for ind in infeasible_pop:
		infeasible_fitness.append(constraint_violation(ind)[0])
	#print("feasible_pop ", feasible_pop)
	#print("infeasible_pop ", infeasible_pop)
	#print("feasible_pop_size ", feasible_pop.size())
	#print("infeasible_pop_size ", infeasible_pop.size())
	
	var best_individual = []
	
	for gen in range(GENERATIONS):
		
		#print("generation ", gen+1)
		# Evaluate fitness and constraint violations
		
		#print("feasible_fitness ",feasible_fitness.size())
		#print("infeasible_fitness ",infeasible_fitness.size())
		# Select best individuals
		if top_ind == []:
			var selected_ind = selection(feasible_pop, feasible_fitness, true)
			#print("selected_ind ", selected_ind[0])
			#print("location top individu ke-1 ", feasible_pop.find(selected_ind[0][0]))
			#print("location top individu ke-2 ", feasible_pop.find(selected_ind[0][1]))
			#print("fitness top individu ke-1 ", objective_function(selected_ind[0][0])[0])
			#print("fitness top individu ke-2 ", objective_function(selected_ind[0][1])[0])
			top_ind = selected_ind[0]
			top_ind_fitness = selected_ind[1]
		else:
			var selected_ind = selection(feasible_pop, feasible_fitness, true)
			#print(selected_ind)
			for i in range(top_ind.size()):
				#print("index ", i)
				for j in range(selected_ind[0].size()):
					#print(top_ind_fitness[i])
					#print("top_ind_fitness[i] ", top_ind_fitness[i])
					#print("selected_ind[1][j] ", selected_ind[1][j])
					if top_ind_fitness[i] <= selected_ind[1][j]:
						top_ind_fitness[i] = selected_ind[1][j]
						top_ind[i] = selected_ind[0][j].duplicate()
						#print("it worked")
						break
				#print("did it loop again?")
			
		#var infeasible_top_pop = selection(infeasible_pop, infeasible_fitness , false)

		# Generate new population with crossover 
		var new_feasible_pop = crossover(feasible_pop, top_ind, true)
		var new_infeasible_pop = crossover(infeasible_pop, top_ind, false)

		# Apply mutation
		for i in range(new_feasible_pop.size()):
			new_feasible_pop[i] = mutate(new_feasible_pop[i])
		for i in range(new_infeasible_pop.size()):
			new_infeasible_pop[i] = mutate(new_infeasible_pop[i])

		# Transfer between populations
		var new_feasible = []
		var feasible_i = 0
		for ind in new_infeasible_pop:
			#print(i," ",new_infeasible_pop[i])
			if constraint_violation(ind)[0] <= 0:
				new_feasible.append(new_infeasible_pop.pop_at(feasible_i))
			feasible_i += 1
		var new_infeasible = []
		feasible_i = 0
		for ind in new_feasible_pop:
			if constraint_violation(ind)[0] > 0:
				new_infeasible.append(new_feasible_pop.pop_at(feasible_i))
			feasible_i += 1

		new_feasible_pop.append_array(new_feasible)
		new_infeasible_pop.append_array(new_infeasible)
		feasible_pop = new_feasible_pop.slice(0, POPULATION_SIZE)
		infeasible_pop = new_infeasible_pop.slice(0, POPULATION_SIZE)
		
		feasible_fitness = []
		infeasible_fitness = []
		
		for ind in feasible_pop:
			feasible_fitness.append(objective_function(ind)[0])
		for ind in infeasible_pop:
			infeasible_fitness.append(constraint_violation(ind)[0])
		
		var best_fitness = feasible_fitness.max()
		
		#print("Generation %d: Best Feasible Fitness = %.4f" % [gen + 1, best_fitness])
		#print("fitness array", feasible_fitness)
		#print("feasible pop size ", feasible_pop.size())
		#print("infeasible pop size ", infeasible_pop.size())
		
		best_individual = []
		for i in range(feasible_fitness.size()):
			if feasible_fitness[i] >= best_fitness:
				best_individual.append(feasible_pop[i])
		
		#print("best index ", best_array_index)
		#print("best array ", feasible_pop[best_array_index], " actual fitness: ", objective_function( feasible_pop[best_array_index]))
		#print top K
		#for i in range(top_ind.size()):
		#	print(i," ","individual: ", top_ind[i], ", fitness (in array): ", top_ind_fitness[i], " fitness (manual calculation): ", objective_function(top_ind[i])[0], " is it the same? ", objective_function(top_ind[i])[0] == top_ind_fitness[i])
		if feasible_pop.size() == 0:
			print("what the fuck")
			break
		#print("feasible pop ", feasible_pop)
		#print("infeasible pop ", infeasible_pop)
	
	var selected_best_individual = best_individual[randi_range(0,best_individual.size()-1)]
	print("selected_best_individual ", selected_best_individual)
	print("objective function ", objective_function(selected_best_individual))
	print("constraint violation ", constraint_violation(selected_best_individual))
	return [selected_best_individual, objective_function(selected_best_individual), constraint_violation(selected_best_individual)]
