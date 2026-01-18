# MazeGenerator.gd
@tool
extends Node

class_name MazeGenerator

const GRID_SIZE = 10
const TILE_LAYERS = 4 # 0: player/goal, 1: elevation, 2: doors, 3: keys
const MAX_ELEVATION_DIFF = 2
const COLORS = {"red": 1, "green": 2, "blue": 3}

@export var gene_pool = []
@export var feasible_population = []
@export var infeasible_population = []
@export var population_size_feasible = 200
var population_size_infeasible = 1000
var generations = 30

@export_tool_button("Generate")
var c: Callable = woah()

func woah():
	initialize_gene_pool()
	initialize_population()
	evolve()

func initialize_gene_pool():
	# Assume we pre-generate or load patterns here
	for _i in range(50): # random patterns
		var pattern = generate_random_pattern(2, 2)
		gene_pool.append({
			"pattern": pattern,
			"fitness": 1.0
		})

func initialize_population():
	for _i in range(population_size_feasible + population_size_infeasible):
		var individual = generate_individual()
		if is_feasible(individual):
			feasible_population.append(individual)
		else:
			infeasible_population.append(individual)

func evolve():
	for _gen in range(generations):
		var new_population_feasible = []
		var new_population_infeasible = []
		
		for pop in [feasible_population, infeasible_population]:
			for individual in pop:
				var offspring = crossover(individual, pick_random(pop))
				mutate(offspring)
				if is_feasible(offspring):
					new_population_feasible.append(offspring)
				else:
					new_population_infeasible.append(offspring)
		feasible_population = select_top(new_population_feasible, population_size_feasible, true)
		infeasible_population = select_top(new_population_infeasible, population_size_infeasible, false)

		update_gene_fitness()
		print("Generation %d - Feasible: %d" % [_gen, feasible_population.size()])

func generate_random_pattern(w, h):
	var pattern = []
	for _y in range(h):
		var row = []
		for _x in range(w):
			var cell = []
			for l in range(TILE_LAYERS):
				match l:
					0:
						cell.append(randi() % 3) # 0=empty, 1=player, 2=goal
					1:
						cell.append(randi_range(1, 6))
					2, 3:
						cell.append(randi() % 4) # no door/key=0, red=1, green=2, blue=3
			row.append(cell)
		pattern.append(row)
	return pattern

func generate_individual():
	var map = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			var gene = pick_gene_from_pool()
			row.append(gene["pattern"][y % gene["pattern"].size()][x % gene["pattern"][0].size()])
		map.append(row)
	return map

func pick_gene_from_pool():
	var fitness_sum = 0.0
	for gene in gene_pool:
		fitness_sum += gene["fitness"]
	var threshold = randf() * fitness_sum
	var cumulative = 0.0
	for gene in gene_pool:
		cumulative += gene["fitness"]
		if cumulative >= threshold:
			return gene
	return gene_pool[randi() % gene_pool.size()]

func crossover(parent1, parent2):
	var child = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			if randi() % 2 == 0:
				row.append(parent1[y][x])
			else:
				row.append(parent2[y][x])
		child.append(row)
	return child

func mutate(individual):
	if randf() < 0.1:
		var y = randi() % GRID_SIZE
		var x = randi() % GRID_SIZE
		individual[y][x] = pick_gene_from_pool()["pattern"][0][0] # just replace randomly

func is_feasible(individual):
	# Very simple feasibility: must have 1 player and 1 goal
	var player_found = false
	var goal_found = false
	for row in individual:
		for cell in row:
			if cell[0] == 1:
				player_found = true
			if cell[0] == 2:
				goal_found = true
	return player_found and goal_found

func evaluate_fitness(individual):
	# A* pathfinding or BFS to find minimum steps
	return pathfinding_steps(individual)

func pathfinding_steps(individual):
	# BFS search from player to goal
	var start = null
	var goal = null
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if individual[y][x][0] == 1:
				start = Vector2(x, y)
			if individual[y][x][0] == 2:
				goal = Vector2(x, y)

	if not start or not goal:
		return INF

	var visited = {}
	var queue = []
	queue.append({"pos": start, "steps": 0})
	visited[start] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current["pos"] == goal:
			return current["steps"]
		for dir in [Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(-1,0)]:
			var next = current["pos"] + dir
			if in_bounds(next) and not visited.has(next) and can_move(individual, current["pos"], next):
				queue.append({"pos": next, "steps": current["steps"] + 1})
				visited[next] = true
	return INF

func in_bounds(pos):
	return pos.x >= 0 and pos.y >= 0 and pos.x < GRID_SIZE and pos.y < GRID_SIZE

func can_move(individual, from_pos, to_pos):
	var from_elev = individual[from_pos.y][from_pos.x][1]
	var to_elev = individual[to_pos.y][to_pos.x][1]
	return abs(from_elev - to_elev) <= MAX_ELEVATION_DIFF

func select_top(population, size, feasible):
	population.sort_custom(func(a, b):
		if feasible:
			return evaluate_fitness(a) < evaluate_fitness(b)
		else:
			return evaluate_fitness(a) > evaluate_fitness(b)
	)
	return population.slice(0, min(size, population.size()))

func update_gene_fitness():
	for gene in gene_pool:
		gene["fitness"] *= 0.9 # decay old fitness

	for pop in [feasible_population, infeasible_population]:
		for individual in pop:
			for y in range(GRID_SIZE):
				for x in range(GRID_SIZE):
					var pattern = individual[y][x]
					for gene in gene_pool:
						if gene["pattern"][0][0] == pattern:
							gene["fitness"] += 0.1

func pick_random(list):
	return list[randi() % list.size()]
