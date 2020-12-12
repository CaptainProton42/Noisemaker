extends Node

var _save_dir: String = "" setget set_save_dir, get_save_dir

func set_save_dir(p_save_dir: String) -> void:
	_save_dir = p_save_dir

func get_save_dir() -> String:
	return _save_dir