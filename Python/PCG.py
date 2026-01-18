import random
import math
import csv
import os
import numpy as np

# ------------------------------
# Parameters
# ------------------------------
POPULATION_SIZE = 100
GENERATIONS = 20
CHROMOSOME_LENGTH = 20

GENERIC_TERRAINS = [105, 104, 101, 102, 103] #turunan 2x lebih lancip, turunan, datar, tanjakan, tanjakan 2x lebih lancip
SET_PIECES = [201, 202, 203] #loop, twister, ramps

WEIGHT_F = 1.0  # flow
WEIGHT_P = 1.0  # pacing
WEIGHT_M = 1.0  # momentum
WEIGHT_S = 1.0  # setpiece

target_fitness = 1.0

# ------------------------------
# GA Data
# ------------------------------
population = []
fitness_scores = []

# ------------------------------
# Import to CSV
# ------------------------------

CSV_PATH = "baseline_results_"+ str(target_fitness) +".csv"

def init_csv():
    with open(CSV_PATH, mode="w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "generation",
            "individual",
            "chromosome",
            "fitness",
            "flow",
            "momentum",
            "pacing",
            "setpiece"
        ])


# ------------------------------
# Genetic Algorithm Core
# ------------------------------
def initialize_population():
    global population
    population = []

    for _ in range(POPULATION_SIZE):
        chromosome = [random.choice(GENERIC_TERRAINS) for _ in range(CHROMOSOME_LENGTH)]
        chromosome = insert_unique_terrain(chromosome)
        population.append(chromosome)


def insert_unique_terrain(chromosome):
    new_chromosome = chromosome.copy()
    idx = random.randint(0, CHROMOSOME_LENGTH - 1)
    new_chromosome[idx] = random.choice(SET_PIECES)
    return new_chromosome


def evolve_population():
    global population, fitness_scores

    init_csv()

    for gen in range(GENERATIONS):
        fitness_scores = []
        fitness_details = []

        # Evaluate population
        for chrom in population:
            metrics = play_level(chrom)
            total_fitness = calculate_fitness(chrom)

            fitness_scores.append(total_fitness)
            fitness_details.append((metrics, total_fitness))

        print(f"Generation {gen + 1} complete.")

        # Write CSV for this generation
        with open(CSV_PATH, mode="a", newline="") as f:
            writer = csv.writer(f)
            for i, (metrics, fit) in enumerate(fitness_details):
                writer.writerow([
                    gen,
                    i,
                    " ".join(map(str, population[i])),
                    fit,
                    metrics["flow"],
                    metrics["momentum"],
                    metrics["pacing"],
                    metrics["setpiece"]
                ])
    

        if gen >= GENERATIONS-1:
            break
            

        # Create next generation
        new_population = []
        for _ in range(POPULATION_SIZE):
            p1 = population[select_parent(3)]
            p2 = population[select_parent(3)]
            child = crossover(p1, p2)
            child = mutate(child)
            new_population.append(child)

        population = new_population
        




def select_parent(tournament_size):
    competitors = [random.randrange(len(population)) for _ in range(tournament_size)]

    best_idx = competitors[0]
    best_fitness = fitness_scores[best_idx]

    for idx in competitors:
        if fitness_scores[idx] > best_fitness:
            best_idx = idx
            best_fitness = fitness_scores[idx]

    return best_idx


def crossover(parent_1, parent_2):
    point1 = random.randint(0, CHROMOSOME_LENGTH // 2 - 1)
    point2 = random.randint(point1 + 1, CHROMOSOME_LENGTH - 1)

    return (
        parent_2[:point1] +
        parent_1[point1:point2] +
        parent_2[point2:]
    )


def mutate(chromosome):
    point1 = random.randint(0, (CHROMOSOME_LENGTH * 2) // 3 - 1)
    point2 = min(point1 + CHROMOSOME_LENGTH // 3, CHROMOSOME_LENGTH)

    segment = chromosome[point1:point2]
    random.shuffle(segment)

    return chromosome[:point1] + segment + chromosome[point2:]


# ------------------------------
# Fitness Function
# ------------------------------
def calculate_fitness(chromosome):
    fitness = play_level(chromosome)

    total_fitness = (
        WEIGHT_F * fitness["flow"]
        + WEIGHT_M * fitness["momentum"]
        + WEIGHT_P * fitness["pacing"]
        + WEIGHT_S * fitness["setpiece"]
    ) / (WEIGHT_F + WEIGHT_M + WEIGHT_P + WEIGHT_S)

    #print("flow ", fitness["flow"])
    #print("momentum ", fitness["momentum"])
    #print("pacing ", fitness["pacing"])
    #print("set piece ", fitness["setpiece"])


    #print("total_fitness", total_fitness)

    fit_error = abs(total_fitness - target_fitness)
    return 1.0 / (1.0 + fit_error)


def play_level(chromosome):
    SPEED_THRESHOLD_MOMENTUM_GAIN = 5.0
    OPTIMAL_MOMENTUM_GAIN = 1.5

    LOOP_MIN_SPEED = 3.6
    RAMP_MIN_SPEED = 2.0
    TWISTER_MIN_SPEED = 1.1

    MIN_IDEAL_SPEED = 3.6
    MAX_IDEAL_SPEED = 6.0

    MAX_VARIANCE = 6.0  # TOP_3

    momentum_gain = 0.0
    momentum_gain_count = 0

    optimal_flow = 0.0

    valid_setpieces = 0.0
    setpiece_count = 0.0

    speeds = []

    current_speed = 0.0

    for terrain in chromosome:
        prev_speed = current_speed
        current_speed = speed_update(terrain, current_speed)
        acceleration = current_speed - prev_speed

        # Momentum
        if current_speed > prev_speed:
            momentum_gain_count += 1
            if current_speed < SPEED_THRESHOLD_MOMENTUM_GAIN:
                momentum_gain += 1 if acceleration >= OPTIMAL_MOMENTUM_GAIN else 0.5
            else: momentum_gain += 0.5

        # Flow
        if MIN_IDEAL_SPEED <= current_speed <= MAX_IDEAL_SPEED:
            optimal_flow += 1
        else:
            if current_speed < MIN_IDEAL_SPEED and current_speed > prev_speed:
                optimal_flow += 0.5
            elif current_speed > MIN_IDEAL_SPEED and current_speed < prev_speed:
                optimal_flow += 0.5

        # Setpiece validation
        if terrain == SET_PIECES[0] and prev_speed >= LOOP_MIN_SPEED:
            valid_setpieces += 1
        elif terrain == SET_PIECES[1] and prev_speed >= TWISTER_MIN_SPEED:
            valid_setpieces += 1
        elif terrain == SET_PIECES[2] and prev_speed >= RAMP_MIN_SPEED:
            valid_setpieces += 1

        if terrain in SET_PIECES:
            setpiece_count += 1

        speeds.append(current_speed)


    speed_avg = np.mean(speeds)

    raw_variance = sum((s - speed_avg) ** 2 for s in speeds) / len(speeds)
    max_variance = (MAX_VARIANCE ** 2) / 4.0 #Variance is maximized when values are split between minimum and maximum possible speeds.

    normalized_variance = max(0.0, min(1.0, raw_variance / max_variance))

    #print("speed", speeds)

    return {
        "flow": optimal_flow/ len(chromosome),
        "momentum": momentum_gain / momentum_gain_count,
        "pacing": normalized_variance,
        "setpiece": valid_setpieces / setpiece_count if setpiece_count > 0 else 0
    }


# ------------------------------
# Speed Update
# ------------------------------
def speed_update(terrain, current_speed):
    TOP_1, TOP_2, TOP_3 = 1, 3.6, 6

    ACC_FLAT = 1.2
    ACC_DOWNSLOPE = 1.8
    ACC_TOP2_DOWNSLOPE = 0.5

    ACC_UPSLOPE = 1.2
    DEC_TOP2_UPSLOPE = -0.2

    DEC_TOP3_UPSCALE_DOUBLE = -0.5
    DEC_TOP2_UPSCALE_DOUBLE = -0.7
    DEC_TOP1_UPSCALE_DOUBLE = -0.2
    DEC_UPSCALE_DOUBLE = -1

    ACC_DOWNSCALE_DOUBLE = 3.6
    ACC_TOP2_DOWNSCALE_DOUBLE = 0.7
    ACC_TOP3_DOWNSCALE_DOUBLE = 0.4

    ACC_TOP2_LOOP = 1.1
    ACC_TOP3_LOOP = 0.1

    DEC_TOP1_RAMPS = -1.2
    DEC_TOP2_RAMPS = -2

    if terrain == GENERIC_TERRAINS[0]:
        current_speed += (
            ACC_TOP3_DOWNSCALE_DOUBLE if current_speed > TOP_3
            else ACC_TOP2_DOWNSCALE_DOUBLE if current_speed > TOP_2
            else ACC_DOWNSCALE_DOUBLE
        )

    elif terrain == GENERIC_TERRAINS[1]:
        current_speed += ACC_TOP2_DOWNSLOPE if current_speed > TOP_2 else ACC_DOWNSLOPE

    elif terrain == GENERIC_TERRAINS[2]:
        if current_speed <= TOP_2:
            current_speed += ACC_FLAT

    elif terrain == GENERIC_TERRAINS[3]:
        if current_speed > TOP_2:
            current_speed += DEC_TOP2_UPSLOPE
            current_speed = max(current_speed, TOP_2)
        elif current_speed < TOP_2:
            current_speed += ACC_UPSLOPE
            current_speed = min(current_speed, TOP_2)

    elif terrain == GENERIC_TERRAINS[4]:
        current_speed += (
            DEC_TOP3_UPSCALE_DOUBLE if current_speed > TOP_3
            else DEC_TOP2_UPSCALE_DOUBLE if current_speed > TOP_2
            else DEC_TOP1_UPSCALE_DOUBLE if current_speed > TOP_1
            else DEC_UPSCALE_DOUBLE
        )

    elif terrain == SET_PIECES[0]:  # loop
        if current_speed > TOP_3:
            current_speed += ACC_TOP3_LOOP
        elif current_speed >= TOP_2:
            current_speed += ACC_TOP2_LOOP
        else:
            current_speed = 0

    elif terrain == SET_PIECES[1]:  # twister
        if current_speed < TOP_1:
            current_speed = 0

    elif terrain == SET_PIECES[2]:  # ramps
        if current_speed > TOP_2:
            current_speed += DEC_TOP2_RAMPS
        elif current_speed > TOP_1:
            current_speed += DEC_TOP1_RAMPS
        else:
            current_speed = 0

    return max(current_speed, 0)


# ------------------------------
# Output Best Rhythm
# ------------------------------
def print_best_rhythm():
    best_fitness = max(fitness_scores)
    best_idx = fitness_scores.index(best_fitness)
    best = population[best_idx]



    print(best_idx, "idx")

    print("Best Rhythm:", " ".join(map(str, best)))
    print("best fitness", best_fitness)
    print("Best Rhythm Fitness:", calculate_fitness(best))

# ----------------------------
# Baseline
# -----------------------------
def initialize_population_baseline():
    global population
    population = []

    TERRAINS = GENERIC_TERRAINS + SET_PIECES

    for _ in range(POPULATION_SIZE):
        chromosome = [random.choice(TERRAINS) for _ in range(CHROMOSOME_LENGTH)]
        chromosome = insert_unique_terrain(chromosome)
        population.append(chromosome)

def create_baseline():
    global population, fitness_scores

    init_csv()

    fitness_scores = []
    fitness_details = []

    # Evaluate population
    for chrom in population:
        metrics = play_level(chrom)
        total_fitness = calculate_fitness(chrom)
        fitness_scores.append(total_fitness)
        fitness_details.append((metrics, total_fitness))

    with open(CSV_PATH, mode="a", newline="") as f:
            writer = csv.writer(f)
            for i, (metrics, fit) in enumerate(fitness_details):
                writer.writerow([
                    "0",
                    i,
                    " ".join(map(str, population[i])),
                    fit,
                    metrics["flow"],
                    metrics["momentum"],
                    metrics["pacing"],
                    metrics["setpiece"]
                ])

# --------------------------------
# Compare
# ------------------------------

def elementwise_match_percentage(list1, list2):
    if len(list1) != len(list2):
        raise ValueError("Lists must be of the same length for element-wise comparison.")

    matches = 0
    # Iterate through both lists simultaneously
    for item1, item2 in zip(list1, list2):
        if item1 == item2:
            matches += 1

    # Calculate percentage
    total_elements = len(list1)
    percentage = (matches / total_elements) * 100
    return round(percentage, 2)

# ------------------------------
# Run
# ------------------------------
if __name__ == "__main__":
    initialize_population()
    evolve_population()
    print_best_rhythm()
    #initialize_population_baseline()
    #create_baseline()
    #print("Fitness:", calculate_fitness([103, 103, 103, 103, 103, 102, 104, 104, 201, 101, 101, 102, 102, 102, 201, 105, 105, 104, 105, 102]))
    #print("Green Hill zone act 1 Fitness:", calculate_fitness([101, 101, 101, 101, 101, 101, 101, 103, 101, 101, 101, 101, 101, 104, 203, 101, 101, 103, 103, 101]))
    #print("Emerald Hill zone act 2 Fitness:", calculate_fitness([105, 101, 104, 104, 101, 101, 101, 101, 105, 102, 102, 201, 105, 105, 201, 105, 105, 102, 104, 101]))
    #print("Aquatic Ruin zone act 2 Fitness:", calculate_fitness([101, 105, 101, 101, 102, 102, 102, 102, 104, 104, 104, 104, 201, 104, 104, 104, 104, 101, 101, 101]))
    #print("Aquatic Ruin PCG result:", calculate_fitness([103, 103, 103, 105, 103, 203, 102, 105, 105, 102, 102, 201, 103, 104, 101, 102, 101, 105, 102, 102]))
    #print("Emerald Hill PCG result:", calculate_fitness([103, 103, 105, 102, 102, 101, 101, 104, 104, 202, 101, 202, 102, 102, 203, 202, 101, 105, 101, 102]))
    #print("Green Hill PCG result:", calculate_fitness([103, 103, 103, 105, 103, 203, 102, 105, 105, 102, 102, 201, 103, 104, 101, 102, 101, 105, 102, 102]))
    #print("Green Hill Comparision", elementwise_match_percentage([103, 104, 103, 104, 202, 103, 101, 101, 102, 103, 103, 103, 102, 102, 101, 101, 102, 103, 101, 101],
    #                                                             [101, 101, 101, 101, 101, 101, 101, 103, 101, 101, 101, 101, 101, 104, 203, 101, 101, 103, 103, 101]))
    #print("Emerald Hill Comparision", elementwise_match_percentage([103, 103, 105, 102, 102, 101, 101, 104, 104, 202, 101, 202, 102, 102, 203, 202, 101, 105, 101, 102],
    #                                                               [105, 101, 104, 104, 101, 101, 101, 101, 105, 102, 102, 201, 105, 105, 201, 105, 105, 102, 104, 101]))
    #print("Aquatic Ruin Comparision", elementwise_match_percentage([103, 103, 105, 102, 102, 101, 101, 104, 104, 202, 101, 202, 102, 102, 203, 202, 101, 105, 101, 102],
    #                                                               [101, 101, 101, 101, 101, 101, 101, 103, 101, 101, 101, 101, 101, 104, 203, 101, 101, 103, 103, 101]))