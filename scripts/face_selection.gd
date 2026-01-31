extends Control

@onready var male_button: TextureButton = $CenterContainer/VBoxContainer/FacesContainer/MaleVBox/MaleButton
@onready var back_button: TextureButton = $BackButtonContainer/BackButton

var back_normal_texture: Texture2D
var back_hover_texture: Texture2D
var is_back_animating := false

const FACE_MALE_PATH := "res://assets/images/male.png"


func _ready() -> void:
	_setup_face_textures()
	male_button.pressed.connect(_on_male_pressed)
	# Back pressed is connected in scene
	back_normal_texture = load("res://assets/images/ui/back_normal.png") as Texture2D
	back_hover_texture = load("res://assets/images/ui/back_hover.png") as Texture2D


func _setup_face_textures() -> void:
	if ResourceLoader.exists(FACE_MALE_PATH):
		male_button.texture_normal = load(FACE_MALE_PATH) as Texture2D
	else:
		male_button.texture_normal = _make_placeholder_face_texture(Color(0.4, 0.5, 0.7))


func _make_placeholder_face_texture(color: Color) -> Texture2D:
	var img := Image.create(200, 280, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex := ImageTexture.create_from_image(img)
	return tex


func _on_male_pressed() -> void:
	GameManager.selected_face = "male"
	var result_scene := _get_result_scene_for_mask(GameManager.selected_mask_path)
	get_tree().change_scene_to_file(result_scene)


func _get_result_scene_for_mask(mask_path: String) -> String:
	if mask_path.ends_with("mask_1.png"):
		return "res://scenes/result_1.tscn"
	if mask_path.ends_with("mask_2.png"):
		return "res://scenes/result_2.tscn"
	if mask_path.ends_with("mask_3.png"):
		return "res://scenes/result_3.tscn"
	return "res://scenes/result_1.tscn"


func _get_play_scene_for_mask(mask_path: String) -> String:
	if mask_path.ends_with("mask_1.png"):
		return "res://scenes/play_1.tscn"
	if mask_path.ends_with("mask_2.png"):
		return "res://scenes/play.tscn"
	if mask_path.ends_with("mask_3.png"):
		return "res://scenes/play_3.tscn"
	return "res://scenes/play.tscn"


func _on_back_pressed() -> void:
	if is_back_animating:
		return
	is_back_animating = true
	# await _back_blink_animation()
	var play_scene := _get_play_scene_for_mask(GameManager.selected_mask_path)
	get_tree().change_scene_to_file(play_scene)


# func _back_blink_animation() -> void:
# 	for i in range(10):
# 		back_button.texture_normal = back_hover_texture
# 		await get_tree().create_timer(0.15).timeout
# 		back_button.texture_normal = back_normal_texture
# 		await get_tree().create_timer(0.15).timeout
# 	back_button.texture_normal = back_hover_texture
# 	await get_tree().create_timer(0.1).timeout
