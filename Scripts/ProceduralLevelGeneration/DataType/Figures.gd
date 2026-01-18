extends Node
class_name Figures

var collection_of_figure: Array[Figure]

func append_figure(figure_id: int, back_preference: Array[int], front_preference: Array[int]):
	collection_of_figure.append(Figure.new(figure_id,back_preference,front_preference))
