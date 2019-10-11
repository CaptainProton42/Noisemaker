tool
extends Node2D

func _ready():
	var i = 250
	print(i)
	yield(get_tree().create_timer(0.5), "timeout")
	var tex = get_node("NoiseGenerator").get_volume_tex()
	var img = tex.get_layer_data(i)
	var imgtex = ImageTexture.new()
	imgtex.create_from_image(img)
	get_node("Sprite5").texture = imgtex