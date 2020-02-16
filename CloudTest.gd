tool
extends Spatial

onready var shader_material = get_node("ShaderQuad").get_surface_material(0)

export var cloud_speed = 0.1
export var detail_speed = 0.01
export var regenerate = false setget set_regenerate

var offset = 0.0
var detail_offset = 0.0

func _ready():
	regenerate()

func set_regenerate(val):
	if (is_inside_tree()):
		regenerate()

func regenerate():
	get_node("WorleyGenerator").generate()
	yield(get_node("WorleyGenerator").generate_volume_texture(), "completed")
	shader_material.set_shader_param("volume", get_node("WorleyGenerator").volume_texture)
	get_node("DetailGenerator").generate()
	yield(get_node("DetailGenerator").generate_volume_texture(), "completed")
	shader_material.set_shader_param("detail", get_node("DetailGenerator").volume_texture)

func _process(delta):
	var bMin = translation - scale / 2.0
	var bMax = translation + scale / 2.0
	shader_material.set_shader_param("bMin", bMin)
	shader_material.set_shader_param("bMax", bMax)

	var sun_color = get_node("WorldEnvironment").environment.background_sky.sun_color
	var sun_lat = get_node("WorldEnvironment").environment.background_sky.sun_latitude * PI / 180.0
	var sun_long = get_node("WorldEnvironment").environment.background_sky.sun_longitude * PI / 180.0

	var sun_pos = Vector3()
	sun_pos.x = cos(sun_lat) * sin(sun_long)
	sun_pos.y = sin(sun_lat)
	sun_pos.z = -cos(sun_lat) * cos(sun_long)
	shader_material.set_shader_param("sunDirection", sun_pos)
	shader_material.set_shader_param("sunColor", sun_color)

	offset += cloud_speed*delta
	detail_offset += (cloud_speed + detail_speed)*delta
	shader_material.set_shader_param("offset", offset)
	shader_material.set_shader_param("detailOffset", detail_offset)