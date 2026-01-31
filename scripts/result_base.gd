extends Control
## Base script cho result scenes. result_1.gd, result_3.gd kế thừa từ đây.

@onready var face_texture: TextureRect = $ResultContainer/FaceTexture
@onready var screenshot_button: TextureButton = $ButtonBar/ScreenshotButtonContainer/ScreenshotButton
@onready var back_button: TextureButton = $ButtonBar/BackButtonContainer/BackButton

var screenshot_normal_texture: Texture2D
var screenshot_hover_texture: Texture2D
var is_screenshot_animating := false
var back_normal_texture: Texture2D
var back_hover_texture: Texture2D
var is_back_animating := false

const FACE_MALE_PATH := "res://assets/images/male.png"


func _ready() -> void:
	_build_result()
	screenshot_normal_texture = load("res://assets/images/ui/screenshot_normal.png") as Texture2D
	screenshot_hover_texture = load("res://assets/images/ui/screenshot_hover.png") as Texture2D
	screenshot_button.texture_hover = screenshot_normal_texture
	back_normal_texture = load("res://assets/images/ui/back_normal.png") as Texture2D
	back_hover_texture = load("res://assets/images/ui/back_hover.png") as Texture2D
	back_button.texture_hover = back_normal_texture


func _build_result() -> void:
	if not face_texture.texture:
		var path := FACE_MALE_PATH if ResourceLoader.exists(FACE_MALE_PATH) else "res://assets/male.png"
		if ResourceLoader.exists(path):
			face_texture.texture = load(path) as Texture2D
	var mask_ref := get_node_or_null("ResultContainer/MaskAlignmentRef")
	if mask_ref:
		if GameManager.decorated_mask_image:
			mask_ref.texture = ImageTexture.create_from_image(GameManager.decorated_mask_image)
			mask_ref.visible = true
		else:
			mask_ref.visible = false


func _on_screenshot_pressed() -> void:
	if is_screenshot_animating:
		return
	is_screenshot_animating = true
	await _screenshot_blink_animation()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var viewport := get_viewport()
	var full_img := viewport.get_texture().get_image()
	var result_container: Control = face_texture.get_parent() as Control
	var canvas_transform := viewport.get_canvas_transform()
	var global_rect: Rect2 = result_container.get_global_rect()
	var pos := (canvas_transform * global_rect.position).floor()
	var end := (canvas_transform * global_rect.end).ceil()
	var x := int(clamp(pos.x, 0, full_img.get_width()))
	var y := int(clamp(pos.y, 0, full_img.get_height()))
	var end_x := int(clamp(end.x, 0, full_img.get_width()))
	var end_y := int(clamp(end.y, 0, full_img.get_height()))
	var w := end_x - x
	var h := end_y - y
	var datetime := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var path := "user://screenshot_%s.png" % datetime
	var err: Error
	if w > 0 and h > 0:
		var cropped := full_img.get_region(Rect2i(x, y, w, h))
		err = cropped.save_png(path)
	else:
		err = full_img.save_png(path)
	if err == OK:
		OS.shell_open(OS.get_user_data_dir())
	else:
		push_error("Screenshot save failed: %s" % error_string(err))
	screenshot_button.texture_normal = screenshot_normal_texture
	is_screenshot_animating = false


func _screenshot_blink_animation() -> void:
	for i in range(10):
		screenshot_button.texture_normal = screenshot_hover_texture
		await get_tree().create_timer(0.15).timeout
		screenshot_button.texture_normal = screenshot_normal_texture
		await get_tree().create_timer(0.15).timeout
	screenshot_button.texture_normal = screenshot_hover_texture
	await get_tree().create_timer(0.1).timeout


func _on_back_pressed() -> void:
	if is_back_animating:
		return
	is_back_animating = true
	await _back_blink_animation()
	GameManager.clear_state()
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


func _back_blink_animation() -> void:
	for i in range(10):
		back_button.texture_normal = back_hover_texture
		await get_tree().create_timer(0.15).timeout
		back_button.texture_normal = back_normal_texture
		await get_tree().create_timer(0.15).timeout
	back_button.texture_normal = back_hover_texture
	await get_tree().create_timer(0.1).timeout
