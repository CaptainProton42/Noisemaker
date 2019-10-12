tool
extends Node

const CHANNEL_RED = 1
const CHANNEL_GREEN = 2
const CHANNEL_BLUE = 4

# Preview settings.
export var preview : bool = false setget set_preview, get_preview
export(int, FLAGS, "r", "g", "b") var preview_channels : int = 7 setget set_preview_channels

const channel = {"enable": true, "num_cells_per_axis": 10}

# Per channel settings.
export var channel_r = channel
export var channel_g = channel
export var channel_b = channel

export var slice : int = 0 setget set_slice
export var texture_resolution : int = 512 setget set_resolution

# Regenerate button.
export var regenerate : bool = false setget set_regenerate

onready var viewport = get_node("Viewport")
onready var canvas = get_node("Viewport/Canvas")
onready var preview_sprite = get_node("Preview")

var volume_texture

func set_regenerate(value):
	if value:
		generate()

func set_preview_channels(flags):
	preview_channels = flags
	preview_sprite.self_modulate = Color(0.0, 0.0, 0.0)
	if (flags) & 1:
		preview_sprite.self_modulate.r = 1.0
	if (flags >> 1) & 1:
		preview_sprite.self_modulate.g = 1.0
	if (flags >> 2) & 1:
		preview_sprite.self_modulate.b = 1.0

func set_preview(value):
	preview_sprite.visible = value

func get_preview():
	return preview_sprite.visible

func generate():
	var points_r
	var points_g
	var points_b
	points_r = generate_points(channel_r.num_cells_per_axis)
	points_g = generate_points(channel_g.num_cells_per_axis)
	points_b = generate_points(channel_b.num_cells_per_axis)
	generate_sampler(CHANNEL_RED, points_r, channel_r.num_cells_per_axis)
	generate_sampler(CHANNEL_GREEN, points_g, channel_g.num_cells_per_axis)
	generate_sampler(CHANNEL_BLUE, points_b, channel_b.num_cells_per_axis)
	set_shader_params()

	viewport.render_target_update_mode = viewport.UPDATE_ONCE

func set_slice(new_slice):
	if new_slice >= texture_resolution:
		new_slice = 0
	elif new_slice <= 0:
		new_slice = texture_resolution - 1
	slice = new_slice
	if is_inside_tree():
		canvas.get_material().set_shader_param("slice", slice)

func set_resolution(resolution):
	texture_resolution = resolution
	set_slice(slice)
	viewport.size.x = resolution
	viewport.size.y = resolution
	canvas.rect_size.x = resolution
	canvas.rect_size.y = resolution
	generate()
	preview_sprite.update()

# Returns offset of each point in normalized cell coordinates.
func generate_points(num_cells_per_axis) -> PoolVector3Array:
	var points : PoolVector3Array = PoolVector3Array()
	points.resize(num_cells_per_axis * num_cells_per_axis * num_cells_per_axis)
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

func set_shader_params():
	canvas.get_material().set_shader_param("enableChannelR", channel_r.enable)
	canvas.get_material().set_shader_param("enableChannelG", channel_g.enable)
	canvas.get_material().set_shader_param("enableChannelB", channel_b.enable)
	canvas.get_material().set_shader_param("numCellsR", channel_r.num_cells_per_axis)
	canvas.get_material().set_shader_param("numCellsG", channel_g.num_cells_per_axis)
	canvas.get_material().set_shader_param("numCellsB", channel_b.num_cells_per_axis)
	canvas.get_material().set_shader_param("numSlices", texture_resolution)
	canvas.get_material().set_shader_param("slice", slice)

func generate_sampler(channel, points, num_cells_per_axis):
	var texture = Texture3D.new()
	texture.create(num_cells_per_axis, num_cells_per_axis, num_cells_per_axis, Image.FORMAT_RGBF)
	for z in range(num_cells_per_axis):
		var image = Image.new()
		image.create(num_cells_per_axis, num_cells_per_axis, false, Image.FORMAT_RGBF)
		image.lock()
		for x in range(num_cells_per_axis):
			for y in range(num_cells_per_axis):
				var index = x + num_cells_per_axis * (y + num_cells_per_axis * z)
				image.set_pixel(x, y, Color(points[index].x, points[index].y, points[index].z, 0.0))
		image.unlock()
		texture.set_layer_data(image, z)
	
	if channel == CHANNEL_RED:
		canvas.get_material().set_shader_param("pointsR", texture)
	elif channel == CHANNEL_GREEN:
		canvas.get_material().set_shader_param("pointsG", texture)
	elif channel == CHANNEL_BLUE:
		canvas.get_material().set_shader_param("pointsB", texture)

func generate_volume_texture():
	var tex = Texture3D.new()
	tex.create(texture_resolution, texture_resolution, texture_resolution, viewport.get_texture().get_data().get_format())
	for layer in range(texture_resolution):
		canvas.get_material().set_shader_param("slice", layer)
		viewport.render_target_update_mode = viewport.UPDATE_ONCE
		yield(get_tree(), "idle_frame") # We need to wait for the viewport to update. Major bottleneck.
		var img = viewport.get_texture().get_data()
		tex.set_layer_data(img, layer)
	volume_texture = tex