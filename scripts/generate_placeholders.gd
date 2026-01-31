@tool
extends EditorScript
## Run from Godot: File -> Run (Ctrl+Shift+X) to generate placeholder assets.

func _run() -> void:
	var base := "res://assets/images/"
	_dir_ensure(base)
	_dir_ensure(base + "decorations/")

	# Mask base (eye mask shape - simple white rectangle)
	var mask := Image.create(400, 120, false, Image.FORMAT_RGBA8)
	mask.fill(Color(1, 1, 1, 0.92))
	_save_png(mask, base + "mask_base.png")

	# Faces
	var face_male := Image.create(600, 800, false, Image.FORMAT_RGBA8)
	face_male.fill(Color(0.45, 0.52, 0.68, 1))
	_save_png(face_male, base + "face_male.png")

	# Decorations (small squares with different colors)
	var decors := [
		["flower1.png", Color(1, 0.4, 0.5)],
		["flower2.png", Color(1, 0.6, 0.3)],
		["leaf1.png", Color(0.3, 0.7, 0.35)],
		["leaf2.png", Color(0.35, 0.65, 0.4)],
		["star.png", Color(1, 0.85, 0.2)],
		["heart.png", Color(0.95, 0.35, 0.45)],
	]
	for name_and_color in decors:
		var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
		img.fill(name_and_color[1])
		_save_png(img, base + "decorations/" + name_and_color[0])

	print("Placeholder assets generated in res://assets/images/")


func _dir_ensure(path: String) -> void:
	var parts := path.replace("res://", "").split("/")
	var current := "res://"
	for p in parts:
		if p.is_empty():
			continue
		current = current + p if current.ends_with("/") else current + "/" + p
		if not DirAccess.dir_exists_absolute(current):
			var err := DirAccess.make_dir_absolute(current)
			if err != OK:
				push_error("Failed to create dir %s: %s" % [current, error_string(err)])
		if not current.ends_with("/"):
			current += "/"


func _save_png(img: Image, path: String) -> void:
	var err := img.save_png(path)
	if err != OK:
		push_error("Failed to save %s: %s" % [path, error_string(err)])
