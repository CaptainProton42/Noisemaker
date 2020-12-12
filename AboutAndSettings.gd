extends Control

func _ready():
	if OS.get_name() == "HTML5":
		get_node("ButtonChooseDir").visible = false
		get_node("LineEditSaveDir").visible = false

func _on_choose_dir_button_pressed():
	get_node("ButtonChooseDir/FileDialog").popup()

func _on_dir_selected(dir):
	get_node("LineEditSaveDir").text = dir
	Settings.set_save_dir(dir)

func _on_line_edit_text_changed(text):
	Settings.set_save_dir(text)
