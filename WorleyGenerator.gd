tool
extends Node2D

const CHANNEL_RED = 1
const CHANNEL_GREEN = 2
const CHANNEL_BLUE = 4

# Preview settings.
export var preview : bool = false setget set_preview, get_preview
export var preview_size : int = 100 setget set_preview_size, get_preview_size
var _preview_size : int

const channel = {"enable": true, "num_cells_per_axis": 10}

# General modifiers
export var inverted : bool = false setget set_inverted, get_inverted
var _inverted = false
export var z_offset : bool = true setget set_z_offset, get_z_offset
var _z_offset = true

# Per channel settings.
export var channel_r = channel
export var channel_g = channel
export var channel_b = channel

export var texture_resolution : int = 512 setget set_texture_resolution

# Regenerate button.
export var regenerate : bool = false setget set_regenerate

onready var viewport = get_node("Viewport")
onready var canvas = get_node("Viewport/Canvas")
onready var preview_sprite = get_node("Preview")

var volume_texture : Texture3D

func set_regenerate(value : bool):
	if not is_inside_tree():
		yield(self, "ready")
	if value:
		generate()

func set_preview_size(p_preview_size : int):
	_preview_size = p_preview_size
	refresh_viewport()

func get_preview_size() -> int:
	return _preview_size

func set_preview(value):
	if is_inside_tree():
		preview_sprite.visible = value

func get_preview() -> bool:
	if is_inside_tree():
		return preview_sprite.visible
	else:
		return false

func set_z_offset(p_z_offset : bool):
	_z_offset = p_z_offset
	generate()

func get_z_offset() -> bool:
	return _z_offset

func set_inverted(p_inverted : bool):
	_inverted = p_inverted
	generate()

func get_inverted() -> bool:
	return _inverted	

func generate():
	var points_r : PoolVector3Array
	var points_g : PoolVector3Array
	var points_b : PoolVector3Array
	points_r = generate_points(channel_r.num_cells_per_axis)
	points_g = generate_points(channel_g.num_cells_per_axis)
	points_b = generate_points(channel_b.num_cells_per_axis)
	generate_sampler(CHANNEL_RED, points_r, channel_r.num_cells_per_axis)
	generate_sampler(CHANNEL_GREEN, points_g, channel_g.num_cells_per_axis)
	generate_sampler(CHANNEL_BLUE, points_b, channel_b.num_cells_per_axis)
	set_shader_params()

	if is_inside_tree():
		viewport.render_target_update_mode = viewport.UPDATE_ONCE
		refresh_viewport()

func set_texture_resolution(resolution : int):
	if not is_inside_tree():
		yield(self, "ready")
	texture_resolution = resolution
	generate()

func refresh_viewport():
	if is_inside_tree():
		viewport.size.x = texture_resolution
		viewport.size.y = texture_resolution
		canvas.rect_size.x = texture_resolution
		canvas.rect_size.y = texture_resolution
		preview_sprite.scale = Vector2(get_preview_size() / canvas.rect_size.x, get_preview_size() / canvas.rect_size.y)
		preview_sprite.update() # Force-draw resize

# Returns offset of each point in normalized cell coordinates.
func generate_points(num_cells_per_axis) -> PoolVector3Array:
	var points : PoolVector3Array = PoolVector3Array()
	points.resize(num_cells_per_axis * num_cells_per_axis * num_cells_per_axis)
	for x in range(num_cells_per_axis):
		for y in range(num_cells_per_axis):
			var random_offset : Vector3 = Vector3(randf(), randf(), 0.0)
			if get_z_offset():
				random_offset.z = randf()
			var index : int = x + num_cells_per_axis * y
			points[index] = random_offset
	return points

# Sets the shader parameters from the Node properties
func set_shader_params():
	canvas.get_material().set_shader_param("inverted", get_inverted())
	canvas.get_material().set_shader_param("enableChannelR", channel_r.enable)
	canvas.get_material().set_shader_param("enableChannelG", channel_g.enable)
	canvas.get_material().set_shader_param("enableChannelB", channel_b.enable)
	canvas.get_material().set_shader_param("numCellsR", channel_r.num_cells_per_axis)
	canvas.get_material().set_shader_param("numCellsG", channel_g.num_cells_per_axis)
	canvas.get_material().set_shader_param("numCellsB", channel_b.num_cells_per_axis)

func update_viewport():
	viewport.render_target_update_mode = viewport.UPDATE_ONCE

# Creates a sampler texture containing the point coordinates withing each cell for each layer and assigns the texture
# to the shader of the corresponding color channel.
func generate_sampler(channel, points, num_cells_per_axis):
	var texture = ImageTexture.new()
	texture.create(num_cells_per_axis, num_cells_per_axis, Image.FORMAT_RGBF)
	var image = Image.new()
	image.create(num_cells_per_axis, num_cells_per_axis, false, Image.FORMAT_RGBF)
	image.lock()
	for x in range(num_cells_per_axis):
		for y in range(num_cells_per_axis):
			var index = x + num_cells_per_axis * y
			image.set_pixel(x, y, Color(points[index].x, points[index].y, points[index].z, 0.0))
	image.unlock()
	texture.set_data(image)
	
	canvas = get_node("Viewport/Canvas")
	match channel:
		CHANNEL_RED:
			canvas.get_material().set_shader_param("pointsR", texture)
		CHANNEL_GREEN:
			canvas.get_material().set_shader_param("pointsG", texture)
		CHANNEL_BLUE:
			canvas.get_material().set_shader_param("pointsB", texture)
