extends Node2D
## Decoration placed on the mask. Supports emoji text or textures.
## Drag and delete are handled by play.gd.

var emoji_text: String = ""
var item_scale: float = 1.0


func setup(texture: Texture2D, pos: Vector2) -> void:
	position = pos
	if has_node("Sprite2D") and texture:
		$Sprite2D.texture = texture
		$Sprite2D.centered = true
		$Sprite2D.visible = true
		if has_node("EmojiLabel"):
			$EmojiLabel.visible = false


func setup_emoji(emoji: String, pos: Vector2, scale_factor: float = 1.0) -> void:
	position = pos
	emoji_text = emoji
	item_scale = scale_factor
	if has_node("EmojiLabel"):
		$EmojiLabel.text = emoji
		$EmojiLabel.visible = true
		$EmojiLabel.scale = Vector2(scale_factor, scale_factor)
	if has_node("Sprite2D"):
		$Sprite2D.visible = false


func set_item_scale(s: float) -> void:
	item_scale = s
	if has_node("EmojiLabel") and $EmojiLabel.visible:
		$EmojiLabel.scale = Vector2(s, s)
	elif has_node("Sprite2D") and $Sprite2D.visible:
		$Sprite2D.scale = Vector2(s * 1.5, s * 1.5)


func get_rect() -> Rect2:
	var size := 48.0 * item_scale
	return Rect2(position - Vector2(size / 2, size / 2), Vector2(size, size))
