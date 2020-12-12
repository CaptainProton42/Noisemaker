extends Control

const CHANNEL_RED = 1
const CHANNEL_GREEN = 2
const CHANNEL_BLUE = 4

onready var generator = get_node("WorleyGenerator")

onready var line_edit_file_name = get_node("LineEditFileName")

func save_to_png():
	var img = generator.viewport.get_texture().get_data()
	FileUtils.save_png(img, line_edit_file_name.text + ".png")

func save_channel_to_png(channel : int):
	var img = generator.viewport.get_texture().get_data()
	img.convert(Image.FORMAT_RGB8)
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

func set_red_channel_enabled(enabled : bool):
	set_channel_enabled(CHANNEL_RED, enabled)

func set_green_channel_enabled(enabled : bool):
	set_channel_enabled(CHANNEL_GREEN, enabled)

func set_blue_channel_enabled(enabled : bool):
	set_channel_enabled(CHANNEL_BLUE, enabled)

func set_channel_enabled(channel : int, enabled : bool):
	match channel:
		CHANNEL_RED:
			generator.channel_r["enable"] = enabled
		CHANNEL_GREEN:
			generator.channel_g["enable"] = enabled
		CHANNEL_BLUE:
			generator.channel_b["enable"] = enabled
	generator.set_shader_params()
	generator.update_viewport()

func set_red_channel_cell_num(cell_num : int):
	set_channel_cell_num(CHANNEL_RED, cell_num)

func set_green_channel_cell_num(cell_num : int):
	set_channel_cell_num(CHANNEL_GREEN, cell_num)

func set_blue_channel_cell_num(cell_num : int):
	set_channel_cell_num(CHANNEL_BLUE, cell_num)

func set_channel_cell_num(channel : int, cell_num : int):
	match channel:
		CHANNEL_RED:
			generator.channel_r["num_cells_per_axis"] = cell_num
		CHANNEL_GREEN:
			generator.channel_g["num_cells_per_axis"] = cell_num
		CHANNEL_BLUE:
			generator.channel_b["num_cells_per_axis"] = cell_num
	generator.generate()
