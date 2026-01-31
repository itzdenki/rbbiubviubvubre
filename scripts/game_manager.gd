extends Node
## Autoload: stores decorated mask and selected face for scene transitions.

var decorated_mask_image: Image
var selected_face: String = ""  # "male"
var selected_mask_path: String = ""  # res://assets/mask/mask_1.png, mask_3

func clear_state() -> void:
	decorated_mask_image = null
	selected_face = ""
	selected_mask_path = ""
