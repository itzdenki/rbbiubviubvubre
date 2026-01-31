@tool
extends EditorScript
## Chạy từ Godot: File -> Run (Ctrl+Shift+X) để tạo mask khớp với result scenes.

func _run() -> void:
	# Kích thước từ MaskAlignmentRef mỗi result scene
	var masks: Array[Dictionary] = [
		{"path": "res://assets/mask/mask_1.png", "w": 350, "h": 449},
		{"path": "res://assets/mask/mask_3.png", "w": 352, "h": 287},
	]
	for m in masks:
		var img := _create_mask_shape(m.w, m.h)
		_save_png(img, m.path)
	print("Mask đã tạo: mask_1 (350x449), mask_3 (352x287)")


func _create_mask_shape(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Vùng trắng = có thể tô màu (hình mặt nạ)
	var margin := int(minf(w, h) * 0.08)
	var inner := Rect2i(margin, margin, w - margin * 2, h - margin * 2)
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			img.set_pixel(x, y, Color(1, 1, 1, 0.95))
	return img


func _save_png(img: Image, path: String) -> void:
	var err := img.save_png(path)
	if err == OK:
		print("Created: ", path)
	else:
		push_error("Failed: %s - %s" % [path, error_string(err)])
