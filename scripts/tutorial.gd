extends Control

@onready var back_button: TextureButton = $BackButtonContainer/BackButton

var back_normal_texture: Texture2D
var back_hover_texture: Texture2D
var is_back_animating := false


func _ready() -> void:
	back_normal_texture = load("res://assets/images/ui/back_normal.png") as Texture2D
	back_hover_texture = load("res://assets/images/ui/back_hover.png") as Texture2D


func _on_back_pressed() -> void:
	if is_back_animating:
		return
	is_back_animating = true
	# await _back_blink_animation()
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


# func _back_blink_animation() -> void:
# 	for i in range(10):
# 		back_button.texture_normal = back_hover_texture
# 		await get_tree().create_timer(0.15).timeout
# 		back_button.texture_normal = back_normal_texture
# 		await get_tree().create_timer(0.15).timeout
# 	back_button.texture_normal = back_hover_texture
# 	await get_tree().create_timer(0.1).timeout
