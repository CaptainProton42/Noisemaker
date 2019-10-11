tool
extends Spatial

onready var noise_generator = get_node("NoiseGenerator")
onready var shader_material = get_node("ShaderQuad").get_surface_material(0)

func _ready():
	noise_generator.texture_resolution = 64
	yield(get_tree().create_timer(0.5), "timeout")
	yield(noise_generator.get_volume_tex(), "completed")
	var noise_tex = noise_generator.volume_tex
	shader_material.set_shader_param("volume", noise_tex)

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