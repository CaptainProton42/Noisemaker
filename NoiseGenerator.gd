tool
extends Viewport

export var num_cells_per_axis : int = 10 setget set_num_cells
export var slice : int = 0 setget set_slice
export var texture_resolution : int = 512 setget set_resolution

var volume_tex

var points

func refresh():
	points = generate_points()
	generate_sampler()
	render_target_update_mode = UPDATE_ONCE

func set_slice(new_slice):
	slice = new_slice
	if is_inside_tree():
		get_node("ColorRect").get_material().set_shader_param("slice", slice)

func set_num_cells(num):
	num_cells_per_axis = num
	if is_inside_tree():
		points = generate_points()
		generate_sampler()

func set_resolution(resolution):
	size.x = resolution
	size.y = resolution
	if is_inside_tree():
		get_node("ColorRect").rect_size.x = resolution
		get_node("ColorRect").rect_size.y = resolution
		texture_resolution = resolution

# Returns offset of each point in normalized cell coordinates.
func generate_points() -> PoolVector3Array:
	var points : PoolVector3Array = PoolVector3Array()
	points.resize(num_cells_per_axis * num_cells_per_axis * num_cells_per_axis)
	var cell_size : float = 1.0 / num_cells_per_axis
	var x : int
	var y : int
	var z : int
	for x in range(num_cells_per_axis):
		for y in range(num_cells_per_axis):
			for z in range(num_cells_per_axis):
				var random_offset : Vector3 = Vector3(randf(), randf(), randf())
				var index : int = x + num_cells_per_axis * (y + num_cells_per_axis * z)
				points[index] = random_offset
	return points

func generate_sampler():
	var image = Image.new()
	var texture = ImageTexture.new()
	image.create(points.size(), 1, false, Image.FORMAT_RGBF)
	image.lock()
	for index in range(points.size()):
		image.set_pixel(index, 0, Color(points[index].x, points[index].y, points[index].z, 0.0))
	texture.create_from_image(image)
	get_node("ColorRect").get_material().set_shader_param("points", texture)
	get_node("ColorRect").get_material().set_shader_param("numCellsPerAxis", num_cells_per_axis)
	get_node("ColorRect").get_material().set_shader_param("numSlices", texture_resolution)
	get_node("ColorRect").get_material().set_shader_param("slice", slice)

func get_volume_tex():
	points = generate_points()
	generate_sampler()
	var tex = Texture3D.new()
	tex.create(texture_resolution, texture_resolution, texture_resolution, get_texture().get_data().get_format())
	for layer in range(texture_resolution):
		get_node("ColorRect").get_material().set_shader_param("slice", layer)
		render_target_update_mode = UPDATE_ONCE
		yield(get_tree(), "idle_frame") # We need to wait for the viewport to update. Major bottleneck.
		var img = get_texture().get_data()
		tex.set_layer_data(img, layer)
	volume_tex = tex