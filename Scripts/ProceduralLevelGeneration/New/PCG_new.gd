@tool
extends TileMap


# ------------------------------
# Parameters
# ------------------------------
const POPULATION_SIZE := 100
const GENERATIONS := 20
const CHROMOSOME_LENGTH := 20

const TERRAINS := [-2, -1, 0, 1, 2]
const UNIQUE_TERRAINS := [5, 6, 7]

const WEIGHT_F := 1.0 # flow
const WEIGHT_P := 1.0 # pacing
const WEIGHT_M := 1.0 # momentum
const WEIGHT_S := 1.0 # setpiece

const TARGET_FITNESS := 1.0

# ------------------------------
# GA Data
# ------------------------------
var population: Array = []
var fitness_scores: Array = []

# ------------------------------
# RNG
# ------------------------------
var rng := RandomNumberGenerator.new()


@export_tool_button("run PCG")
var pcg = func():
	rng.randomize()
	initialize_population()
	evolve_population()
	generate_level_terrain(get_and_print_best_rhythm())


# ------------------------------
# Genetic Algorithm Core
# ------------------------------
func initialize_population():
	population.clear()

	for i in POPULATION_SIZE:
		var chromosome := []
		for j in CHROMOSOME_LENGTH:
			chromosome.append(TERRAINS[rng.randi_range(0, TERRAINS.size() - 1)])

		chromosome = insert_unique_terrain(chromosome)
		population.append(chromosome)


func insert_unique_terrain(chromosome: Array) -> Array:
	var new_chromosome := chromosome.duplicate()
	var idx := rng.randi_range(0, CHROMOSOME_LENGTH - 1)
	new_chromosome[idx] = UNIQUE_TERRAINS[rng.randi_range(0, UNIQUE_TERRAINS.size() - 1)]
	return new_chromosome


func evolve_population():

	for gen in GENERATIONS:
		fitness_scores.clear()
		var fitness_details := []

		# Evaluate
		for chrom in population:
			var metrics := play_level(chrom)
			var total_fitness := calculate_fitness(chrom)

			fitness_scores.append(total_fitness)
			fitness_details.append({
				"metrics": metrics,
				"fitness": total_fitness
			})

		# New population
		var new_population := []
		for i in POPULATION_SIZE:
			var p1 = population[select_parent(3)]
			var p2 = population[select_parent(3)]
			var child := crossover(p1, p2)
			child = mutate(child)
			new_population.append(child)

		population = new_population
		print("Generation %d complete." % (gen + 1))


func select_parent(tournament_size: int) -> int:
	var competitors := []
	for i in tournament_size:
		competitors.append(rng.randi_range(0, population.size() - 1))

	var best_idx = competitors[0]
	var best_fitness = fitness_scores[best_idx]

	for idx in competitors:
		if fitness_scores[idx] > best_fitness:
			best_idx = idx
			best_fitness = fitness_scores[idx]

	return best_idx


func crossover(p1: Array, p2: Array) -> Array:
	var point1 := rng.randi_range(0, CHROMOSOME_LENGTH / 2.0 - 1.0)
	var point2 := rng.randi_range(point1 + 1, CHROMOSOME_LENGTH - 1)

	return (
		p2.slice(0, point1)
		+ p1.slice(point1, point2)
		+ p2.slice(point2)
	)


func mutate(chromosome: Array) -> Array:
	var point1 = rng.randi_range(0, (CHROMOSOME_LENGTH * 2.0) / 3.0 - 1.0)
	var point2 = min(point1 + CHROMOSOME_LENGTH / 3.0, CHROMOSOME_LENGTH)

	var segment := chromosome.slice(point1, point2)
	segment.shuffle()

	return chromosome.slice(0, point1) + segment + chromosome.slice(point2)


# ------------------------------
# Fitness Function
# ------------------------------
func calculate_fitness(chromosome: Array) -> float:
	var fitness := play_level(chromosome)

	var total_fitness = ((WEIGHT_F * fitness["flow"]
		+ WEIGHT_M * fitness["momentum"]
		+ WEIGHT_P * fitness["pacing"]
		+ WEIGHT_S * fitness["setpiece"])
		/ (WEIGHT_F + WEIGHT_M + WEIGHT_P + WEIGHT_S))

	var fit_error = abs(total_fitness - TARGET_FITNESS)
	return 1.0 / (1.0 + fit_error)


func play_level(chromosome: Array) -> Dictionary:
	const SPEED_THRESHOLD_MOMENTUM_GAIN := 5.0
	const OPTIMAL_MOMENTUM_GAIN := 1.5

	const LOOP_MIN_SPEED := 3.6
	const RAMP_MIN_SPEED := 2.0
	const TWISTER_MIN_SPEED := 1.1

	const MIN_IDEAL_SPEED := 3.6
	const MAX_IDEAL_SPEED := 6.0

	var momentum_gain := 0.0
	var momentum_gain_count := 0.0
	var optimal_flow := 0.0

	var valid_setpieces := 0.0
	var setpiece_count := 0.0

	var speeds := []
	var current_speed := 0.0

	for terrain in chromosome:
		var prev_speed := current_speed
		current_speed = speed_update(terrain, current_speed)
		var acceleration := current_speed - prev_speed

		# Momentum
		if current_speed > prev_speed:
			momentum_gain_count += 1
			if current_speed < SPEED_THRESHOLD_MOMENTUM_GAIN:
				momentum_gain += 1 if acceleration >= OPTIMAL_MOMENTUM_GAIN else 0.5
			else:
				momentum_gain += 0.5

		# Flow
		if MIN_IDEAL_SPEED <= current_speed and current_speed <= MAX_IDEAL_SPEED:
			optimal_flow += 1
		else:
			if current_speed < MIN_IDEAL_SPEED and current_speed > prev_speed:
				optimal_flow += 0.5
			elif current_speed > MIN_IDEAL_SPEED and current_speed < prev_speed:
				optimal_flow += 0.5

		# Setpiece
		if terrain == 5 and prev_speed >= LOOP_MIN_SPEED:
			valid_setpieces += 1
		elif terrain == 6 and prev_speed >= TWISTER_MIN_SPEED:
			valid_setpieces += 1
		elif terrain == 7 and prev_speed >= RAMP_MIN_SPEED:
			valid_setpieces += 1

		if terrain > 4:
			setpiece_count += 1

		speeds.append(current_speed)

	# Pacing
	const DESIGNED_SPEED_UPPER := 6.0

	var speed_avg = speeds.reduce(func(a, b): return a + b, 0.0) / speeds.size()

	var raw_variance := 0.0
	for s in speeds:
		raw_variance += pow(s - speed_avg, 2)
	raw_variance /= speeds.size()

	var max_variance = pow(DESIGNED_SPEED_UPPER, 2) / 4.0
	var normalized_variance = clamp(raw_variance / max_variance, 0.0, 1.0)

	return {
		"flow": optimal_flow / chromosome.size(),
		"momentum": momentum_gain / momentum_gain_count if momentum_gain_count > 0 else 0,
		"pacing": normalized_variance,
		"setpiece": valid_setpieces / setpiece_count if setpiece_count > 0 else 0
	}


# ------------------------------
# Speed Update
# ------------------------------
func speed_update(terrain: int, current_speed: float) -> float:
	const TOP_1 := 1.0
	const TOP_2 := 3.6
	const TOP_3 := 6.0

	const ACC_FLAT := 1.2
	const ACC_DOWNSLOPE := 1.8
	const ACC_TOP2_DOWNSLOPE := 0.5

	const ACC_UPSLOPE := 1.2
	const DEC_TOP2_UPSLOPE := -0.2

	const DEC_TOP3_UPSCALE_DOUBLE := -0.5
	const DEC_TOP2_UPSCALE_DOUBLE := -0.7
	const DEC_TOP1_UPSCALE_DOUBLE := -0.2
	const DEC_UPSCALE_DOUBLE := -1.0

	const ACC_DOWNSCALE_DOUBLE := 3.6
	const ACC_TOP2_DOWNSCALE_DOUBLE := 0.7
	const ACC_TOP3_DOWNSCALE_DOUBLE := 0.4

	const ACC_TOP2_LOOP := 1.1
	const ACC_TOP3_LOOP := 0.1

	const DEC_TOP1_RAMPS := -1.2
	const DEC_TOP2_RAMPS := -2.0

	match terrain:
		-2:
			current_speed += (
				ACC_TOP3_DOWNSCALE_DOUBLE if current_speed > TOP_3
				else ACC_TOP2_DOWNSCALE_DOUBLE if current_speed > TOP_2
				else ACC_DOWNSCALE_DOUBLE
			)
		-1:
			current_speed += ACC_TOP2_DOWNSLOPE if current_speed > TOP_2 else ACC_DOWNSLOPE
		0:
			if current_speed <= TOP_2:
				current_speed += ACC_FLAT
		1:
			if current_speed > TOP_2:
				current_speed = max(current_speed + DEC_TOP2_UPSLOPE, TOP_2)
			elif current_speed < TOP_2:
				current_speed = min(current_speed + ACC_UPSLOPE, TOP_2)
		2:
			current_speed += (
				DEC_TOP3_UPSCALE_DOUBLE if current_speed > TOP_3
				else DEC_TOP2_UPSCALE_DOUBLE if current_speed > TOP_2
				else DEC_TOP1_UPSCALE_DOUBLE if current_speed > TOP_1
				else DEC_UPSCALE_DOUBLE
			)
		5:
			if current_speed > TOP_3:
				current_speed += ACC_TOP3_LOOP
			elif current_speed >= TOP_2:
				current_speed += ACC_TOP2_LOOP
			else:
				current_speed = 0
		6:
			if current_speed < TOP_1:
				current_speed = 0
		7:
			if current_speed > TOP_2:
				current_speed += DEC_TOP2_RAMPS
			elif current_speed > TOP_1:
				current_speed += DEC_TOP1_RAMPS
			else:
				current_speed = 0

	return max(current_speed, 0.0)


# ------------------------------
# Output
# ------------------------------
func get_and_print_best_rhythm():
	var best_idx := 0
	for i in fitness_scores.size():
		if fitness_scores[i] > fitness_scores[best_idx]:
			best_idx = i

	print("Best Rhythm:", population[best_idx])
	print("Fitness:", fitness_scores[best_idx])
	print("Best Rhythm Fitness:", calculate_fitness(population[best_idx]))
	
	return population[best_idx]

func generate_level_terrain(chromosome):
	clear_layer(0)
	## set terrain
	var flat = tile_set.get_pattern(33)
	var downcline = tile_set.get_pattern(29)
	var upcline = tile_set.get_pattern(28)
	var double_upcline = tile_set.get_pattern(31)
	var double_downcline = tile_set.get_pattern(30)
	## set set piece
	var ramps_up = tile_set.get_pattern(24)
	var twister = tile_set.get_pattern(9)
	var loops = tile_set.get_pattern(47)
	
	var current_height = 0
	var current_length = 0
	for i in chromosome:
		if i == 0: #flat
			set_pattern(0, Vector2i(current_length,current_height), flat)
		elif i == 1: #up
			set_pattern(0, Vector2i(current_length,current_height-2), upcline)
			current_height -= 2
		elif i == -1: #down
			set_pattern(0, Vector2i(current_length,current_height), downcline)
			
			current_height += 2
		elif i == 2: #double up
			set_pattern(0, Vector2i(current_length,current_height-4), double_upcline)
			current_height -= 4
		elif i == -2: #double down
			set_pattern(0, Vector2i(current_length,current_height), double_downcline)
			current_height += 4
		elif i == 5: #loops
			set_pattern(0, Vector2i(current_length,current_height-12), loops)
		elif i == 6: #twister
			set_pattern(0, Vector2i(current_length,current_height), twister)
			current_length += 16
		elif i == 7: #ramps up
			set_pattern(0, Vector2i(current_length,current_height-4), ramps_up)
			current_height -= 4
		current_length += 8
