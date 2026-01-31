extends Control

@onready var play_button: TextureButton = $VBoxContainer/PlayButtonContainer/PlayButton
@onready var tutorial_button: TextureButton = $VBoxContainer/TutorialButtonContainer/TutorialButton

var play_normal_texture: Texture2D
var play_hover_texture: Texture2D
var tutorial_normal_texture: Texture2D
var tutorial_hover_texture: Texture2D
var is_play_animating := false
var is_tutorial_animating := false


func _ready() -> void:
	# Play button textures
	play_normal_texture = load("res://assets/images/ui/play_normal.png") as Texture2D
	play_hover_texture = load("res://assets/images/ui/play_hover.png") as Texture2D

	# Tutorial button textures
	tutorial_normal_texture = load("res://assets/images/ui/tutorial_normal.png") as Texture2D
	tutorial_hover_texture = load("res://assets/images/ui/tutorial_hover.png") as Texture2D

func _on_play_pressed() -> void:
	if is_play_animating:
		return
	is_play_animating = true
	# await _play_blink_animation(play_button, play_normal_texture, play_hover_texture)
	get_tree().change_scene_to_file("res://scenes/mask_selection.tscn")


func _on_tutorial_pressed() -> void:
	if is_tutorial_animating:
		return
	is_tutorial_animating = true
	# await _play_blink_animation(tutorial_button, tutorial_normal_texture, tutorial_hover_texture)
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")


# func _play_blink_animation(btn: TextureButton, tex_normal: Texture2D, tex_hover: Texture2D) -> void:
# 	# Blink for 2 seconds total (10 blinks, each cycle = 0.2s)
# 	for i in range(10):
# 		btn.texture_normal = tex_hover
# 		await get_tree().create_timer(0.1).timeout
# 		btn.texture_normal = tex_normal
# 		await get_tree().create_timer(0.1).timeout
# 	btn.texture_normal = tex_hover
# 	await get_tree().create_timer(0.1).timeout
