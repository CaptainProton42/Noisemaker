extends Control

const CHANNEL_RED = 1
const CHANNEL_GREEN = 2
const CHANNEL_BLUE = 4

onready var generator_r = OpenSimplexNoise.new()
onready var generator_g = OpenSimplexNoise.new()
onready var generator_b = OpenSimplexNoise.new()

const channel_options = {"enabled" : true, "octaves" : 3, "lacunarity" : 2.0, "period" : 64.0, "persistence" : 0.5}

var channel_r = channel_options.duplicate()
var channel_b = channel_options.duplicate()
var channel_g = channel_options.duplicate()

var resolution : int = 256

var inverted : bool = false

onready var img = Image.new()

onready var preview = get_node("Preview") 

onready var line_edit_file_name = get_node("LineEditFileName")

func _ready():
	refresh()

func set_enabled(enabled : bool, channel : int):
	match channel:
		CHANNEL_RED:
			channel_r["enabled"] = enabled
		CHANNEL_GREEN:
			channel_g["enabled"] = enabled
		CHANNEL_BLUE:
			channel_b["enabled"] = enabled
	refresh(false)

func set_param(value, param_name : String, channel : int):
	var generator_ref
	match channel:
		CHANNEL_RED:
			channel_r[param_name] = value
			generator_ref = [generator_r]
		CHANNEL_GREEN:
			channel_g[param_name] = value
			generator_ref = [generator_g]
		CHANNEL_BLUE:
			channel_b[param_name] = value
			generator_ref = [generator_b]
	match param_name:
		"lacunarity":
			generator_ref[0].lacunarity = value
		"octaves":
			generator_ref[0].octaves = value
		"period":
			generator_ref[0].period = value
		"persistence":
			generator_ref[0].persistence = value
	refresh(false)
	
func set_inverted(p_inverted : bool):
	inverted = p_inverted
	refresh(false)

func set_resolution(p_resolution : int):
	resolution = p_resolution
	refresh(false)

func generate(reseed : bool = true):
	if reseed:
		generator_r.seed = randi()
		generator_g.seed = randi()
		generator_b.seed = randi()
	var img_data = PoolByteArray()
	img_data.resize(resolution * resolution * 3)
	for i in range(img_data.size()):
		img_data[i] = 0
	if channel_r["enabled"]:
		var img_r = generator_r.get_image(resolution, resolution)
		img_r.convert(Image.FORMAT_RGB8)
		for i in range(0, img_data.size(), 3):
			img_data[i] = img_r.get_data()[i]
			if inverted:
				img_data[i] = 255 - img_data[i]
	if channel_g["enabled"]:
		var img_g = generator_g.get_image(resolution, resolution)
		img_g.convert(Image.FORMAT_RGB8)
		for i in range(0, img_data.size(), 3):
			img_data[i+1] = img_g.get_data()[i]
			if inverted:
				img_data[i+1] = 255 - img_data[i+1]
	if channel_b["enabled"]:
		var img_b = generator_b.get_image(resolution, resolution)
		img_b.convert(Image.FORMAT_RGB8)
		for i in range(0, img_data.size(), 3):
			img_data[i+2] = img_b.get_data()[i]
			if inverted:
				img_data[i+2] = 255 - img_data[i+2]

	img = Image.new()
	img.create_from_data(resolution, resolution, false, Image.FORMAT_RGB8, img_data)


func display():
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags = 0
	preview.texture = tex

func refresh(reseed : bool = true):
	generate(reseed)
	display()

func save_channel_to_png(channel : int):
	var img_data = img.get_data()
	var channel_name = ""
	match channel:
		CHANNEL_RED:
			for i in range(0, img_data.size(), 3):
				img_data[i+1] = img_data[i]
				img_data[i+2] = img_data[i]
			channel_name = "r"
		CHANNEL_GREEN:
			for i in range(0, img_data.size(), 3):
				img_data[i] = img_data[i+1]
				img_data[i+2] = img_data[i+1]
			channel_name = "g"
		CHANNEL_BLUE:
			for i in range(0, img_data.size(), 3):
				img_data[i] = img_data[i+2]
				img_data[i+1] = img_data[i+2]
			channel_name = "b"
	img.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGB8, img_data)
	FileUtils.save_png(img, line_edit_file_name.text + "_" + channel_name + ".png")

func save_to_png():
	FileUtils.save_png(img, line_edit_file_name.text + ".png")
