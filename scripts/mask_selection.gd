extends Control

@onready var mask1_button: TextureButton = $CenterContainer/VBoxContainer/MasksContainer/Mask1VBox/Mask1Button
@onready var mask3_button: TextureButton = $CenterContainer/VBoxContainer/MasksContainer/Mask3VBox/Mask3Button
@onready var back_button: TextureButton = $BackButtonContainer/BackButton

var back_normal_texture: Texture2D
var back_hover_texture: Texture2D
var is_back_animating := false

const MASK_1_PATH := "res://assets/mask/mask_1.png"
const MASK_3_PATH := "res://assets/mask/mask_3.png"


func _ready() -> void:
	# _setup_mask_textures()
	# mask1_button.pressed.connect(_on_mask1_pressed)
	# mask3_button.pressed.connect(_on_mask3_pressed)
	back_normal_texture = load("res://assets/images/ui/back_normal.png") as Texture2D
	back_hover_texture = load("res://assets/images/ui/back_hover.png") as Texture2D


# func _setup_mask_textures() -> void:
# 	if ResourceLoader.exists(MASK_1_PATH):
# 		mask1_button.texture_normal = load(MASK_1_PATH) as Texture2D
# 	else:
# 		mask1_button.texture_normal = _make_placeholder_mask_texture()
# 	if ResourceLoader.exists(MASK_3_PATH):
# 		mask3_button.texture_normal = load(MASK_3_PATH) as Texture2D
# 	else:
# 		mask3_button.texture_normal = _make_placeholder_mask_texture()


# func _make_placeholder_mask_texture() -> Texture2D:
# 	var img := Image.create(160, 100, false, Image.FORMAT_RGBA8)
# 	img.fill(Color(0.5, 0.5, 0.55, 1))
# 	return ImageTexture.create_from_image(img)


func _on_mask1_pressed() -> void:
	GameManager.selected_mask_path = MASK_1_PATH
	get_tree().change_scene_to_file("res://scenes/play_1.tscn")


func _on_mask3_pressed() -> void:
	GameManager.selected_mask_path = MASK_3_PATH
	get_tree().change_scene_to_file("res://scenes/play_3.tscn")


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
