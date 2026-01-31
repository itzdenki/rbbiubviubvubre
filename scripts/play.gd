extends Control

@onready var color_picker: ColorPickerButton = $MarginContainer/HBoxContainer/ColorPanel/ColorPickerButton
@onready var color_presets: GridContainer = $MarginContainer/HBoxContainer/ColorPanel/ColorPresets
@onready var brush_slider: HSlider = $MarginContainer/HBoxContainer/ColorPanel/BrushSlider
@onready var brush_label: Label = $MarginContainer/HBoxContainer/ColorPanel/BrushLabel
@onready var mask_canvas: SubViewportContainer = $MarginContainer/HBoxContainer/CenterPanel/MaskCanvas
@onready var sub_viewport: SubViewport = $MarginContainer/HBoxContainer/CenterPanel/MaskCanvas/SubViewport
@onready var mask_root: Control = $MarginContainer/HBoxContainer/CenterPanel/MaskCanvas/SubViewport/MaskRoot
@onready var paint_texture: TextureRect = $MarginContainer/HBoxContainer/CenterPanel/MaskCanvas/SubViewport/MaskRoot/PaintTexture
@onready var mask_texture: TextureRect = $MarginContainer/HBoxContainer/CenterPanel/MaskCanvas/SubViewport/MaskRoot/MaskTexture
@onready var decorations_container: Node2D = $MarginContainer/HBoxContainer/CenterPanel/MaskCanvas/SubViewport/MaskRoot/DecorationsContainer
@onready var decor_grid: GridContainer = $MarginContainer/HBoxContainer/DecorationsPanel/ScrollContainer/DecorGrid
@onready var clear_button: TextureButton = $BottomBar/ClearButtonContainer/ClearButton
@onready var done_button: TextureButton = $BottomBar/DoneButtonContainer/DoneButton

var selected_emoji: String = ""
var selected_decor_scene: PackedScene
var paint_color := Color(1.0, 0.8, 0.9, 1.0)  # Default soft pink
var brush_size := 15
var _dragging_decor: Node2D
var _drag_offset := Vector2.ZERO

# Paint system
var paint_image: Image
var paint_image_texture: ImageTexture
var mask_stencil_image: Image
var is_painting := false
var last_paint_pos := Vector2.ZERO
var paint_mode := true  # true = paint mode, false = decoration mode
var eraser_mode := false  # true = eraser mode
var done_normal_texture: Texture2D
var done_hover_texture: Texture2D
var is_done_animating := false
var clear_normal_texture: Texture2D
var clear_hover_texture: Texture2D
var is_clear_animating := false
var color_preset_buttons: Array[Button] = []
var eraser_button: Button
var selected_color_index := 0
var brush_cursor: Control  # Brush preview circle

# Pre-set color templates (cute pastel colors)
const COLOR_PRESETS := [
	Color(1.0, 0.8, 0.9, 1.0),    # Soft Pink
	Color(0.9, 0.7, 0.8, 1.0),    # Rose
	Color(1.0, 0.9, 0.8, 1.0),    # Peach
	Color(0.8, 0.9, 1.0, 1.0),    # Light Blue
	Color(0.85, 1.0, 0.85, 1.0),  # Mint Green
	Color(1.0, 1.0, 0.85, 1.0),   # Cream
	Color(0.95, 0.85, 1.0, 1.0),  # Lavender
	Color(1.0, 0.95, 0.8, 1.0),   # Light Gold
	Color(1.0, 0.6, 0.7, 1.0),    # Hot Pink
	Color(1.0, 0.85, 0.85, 1.0),  # Coral
	Color(0.7, 0.85, 1.0, 1.0),   # Sky Blue
	Color(0.95, 0.9, 0.95, 1.0),  # Lilac
]

# Kích thước mask khớp với result_1, result_3 (MaskAlignmentRef)
# Có thể override trong Inspector cho từng play scene - nếu > 0 sẽ dùng thay vì MASK_SIZES
@export var mask_content_width_override: int = 0
@export var mask_content_height_override: int = 0

const MASK_SIZES := {
	"res://assets/mask/mask_1.png": Vector2i(350, 449),
	"res://assets/mask/mask_3.png": Vector2i(352, 287),
}
var MASK_CONTENT_WIDTH := 350
var MASK_CONTENT_HEIGHT := 449

# Emoji decorations palette
const EMOJI_DECORATIONS := [
	"🌸", "🌺", "🌼", "🌻", "🌷", "🌹",
	"💮", "🏵️", "💐", "🍀", "🌿", "🍃",
	"⭐", "✨", "💫", "🌟", "💎", "💖",
	"❤️", "💕", "💗", "💝", "🦋", "🐝",
	"🎀", "🎗️", "🪷", "🌈", "☁️", "🧿",
]


func _ready() -> void:
	_setup_mask_and_paint()
	_setup_color_presets()
	_setup_brush_slider()
	_setup_brush_cursor()
	color_picker.color_changed.connect(_on_color_changed)
	color_picker.color = paint_color
	clear_button.pressed.connect(_on_clear_pressed)
	done_button.pressed.connect(_on_done_pressed)
	# Clear button textures
	clear_normal_texture = load("res://assets/images/ui/clear_normal.png") as Texture2D
	clear_hover_texture = load("res://assets/images/ui/clear_hover.png") as Texture2D
	# Done button textures
	done_normal_texture = load("res://assets/images/ui/done_normal.png") as Texture2D
	done_hover_texture = load("res://assets/images/ui/done_hover.png") as Texture2D
	_populate_emoji_palette()
	mask_canvas.gui_input.connect(_on_mask_canvas_gui_input)
	mask_canvas.mouse_entered.connect(_on_mask_canvas_mouse_entered)
	mask_canvas.mouse_exited.connect(_on_mask_canvas_mouse_exited)


func _setup_brush_slider() -> void:
	brush_slider.min_value = 5
	brush_slider.max_value = 40
	brush_slider.value = brush_size
	brush_slider.value_changed.connect(_on_brush_size_changed)
	_update_brush_label()


func _on_brush_size_changed(value: float) -> void:
	brush_size = int(value)
	_update_brush_label()
	_update_brush_cursor()


func _update_brush_label() -> void:
	brush_label.text = "🖌️ Brush: %d" % brush_size


func _setup_brush_cursor() -> void:
	brush_cursor = Control.new()
	brush_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brush_cursor.set_script(preload("res://scripts/brush_cursor.gd"))
	add_child(brush_cursor)
	brush_cursor.visible = false
	_update_brush_cursor()


func _update_brush_cursor() -> void:
	if brush_cursor and brush_cursor.has_method("set_brush_size"):
		var display_size := _get_brush_display_size()
		brush_cursor.set_brush_size(display_size)
		if eraser_mode:
			brush_cursor.set_brush_color(Color(0.8, 0.8, 0.8, 0.8))  # Gray for eraser
		else:
			brush_cursor.set_brush_color(Color(paint_color.r, paint_color.g, paint_color.b, 0.6))


func _get_brush_display_size() -> float:
	if mask_canvas.size.x > 0 and MASK_CONTENT_WIDTH > 0:
		return brush_size * (mask_canvas.size.x / float(MASK_CONTENT_WIDTH))
	return float(brush_size)


func _on_mask_canvas_mouse_entered() -> void:
	if paint_mode and brush_cursor:
		brush_cursor.visible = true


func _on_mask_canvas_mouse_exited() -> void:
	if brush_cursor:
		brush_cursor.visible = false


func _setup_color_presets() -> void:
	# Add eraser button first
	eraser_button = Button.new()
	eraser_button.custom_minimum_size = Vector2(32, 32)
	eraser_button.text = "🧽"
	eraser_button.add_theme_font_size_override("font_size", 20)
	eraser_button.tooltip_text = "Eraser"
	eraser_button.pressed.connect(_on_eraser_pressed)
	color_presets.add_child(eraser_button)
	
	# Add color preset buttons
	for i in range(COLOR_PRESETS.size()):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(32, 32)
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_PRESETS[i]
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.pressed.connect(_on_color_preset_pressed.bind(i, COLOR_PRESETS[i]))
		color_presets.add_child(btn)
		color_preset_buttons.append(btn)
	
	# Highlight first color by default
	_update_color_button_highlights()


func _on_color_preset_pressed(index: int, c: Color) -> void:
	paint_color = c
	color_picker.color = c
	paint_mode = true
	eraser_mode = false
	selected_color_index = index
	_update_color_button_highlights()
	_highlight_paint_mode()
	_update_brush_cursor()


func _on_eraser_pressed() -> void:
	eraser_mode = true
	paint_mode = true
	selected_color_index = -1
	_update_color_button_highlights()
	_highlight_paint_mode()
	_update_brush_cursor()


func _update_color_button_highlights() -> void:
	# Update eraser button highlight
	if eraser_button:
		if eraser_mode:
			eraser_button.modulate = Color(1.3, 1.3, 1.0)  # Brighter
			var style := StyleBoxFlat.new()
			style.bg_color = Color(1.0, 1.0, 0.85)  # Light yellow background
			style.border_color = Color(1.0, 0.85, 0.0)  # Yellow border
			style.set_border_width_all(3)
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			style.corner_radius_bottom_left = 8
			style.corner_radius_bottom_right = 8
			eraser_button.add_theme_stylebox_override("normal", style)
			eraser_button.add_theme_stylebox_override("hover", style)
			eraser_button.add_theme_stylebox_override("pressed", style)
		else:
			eraser_button.modulate = Color.WHITE
			eraser_button.remove_theme_stylebox_override("normal")
			eraser_button.remove_theme_stylebox_override("hover")
			eraser_button.remove_theme_stylebox_override("pressed")
	
	# Update color preset buttons
	for i in range(color_preset_buttons.size()):
		var btn := color_preset_buttons[i]
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_PRESETS[i]  # Color inside
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		
		if i == selected_color_index and not eraser_mode:
			# Highlight selected color: Pink border + brighter + color inside
			btn.modulate = Color(1.2, 1.2, 1.2)
			style.border_color = Color(1.0, 0.4, 0.6)  # Pink border
			style.set_border_width_all(3)
		else:
			btn.modulate = Color.WHITE
			style.border_color = Color(0.7, 0.7, 0.7)
			style.set_border_width_all(1)
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)


func _setup_mask_and_paint() -> void:
	# Load the mask image (từ mask selection hoặc mặc định)
	var mask_path: String = GameManager.selected_mask_path if GameManager.selected_mask_path else "res://assets/mask/mask_1.png"
	var sz: Vector2i = MASK_SIZES.get(mask_path, Vector2i(350, 449))
	# Ưu tiên kích thước override từ Inspector nếu đã set
	if mask_content_width_override > 0 and mask_content_height_override > 0:
		MASK_CONTENT_WIDTH = mask_content_width_override
		MASK_CONTENT_HEIGHT = mask_content_height_override
	else:
		MASK_CONTENT_WIDTH = sz.x
		MASK_CONTENT_HEIGHT = sz.y
	# Cập nhật MaskRoot size và vị trí (viewport 750x500)
	sub_viewport.size = Vector2i(750, 500)
	var mx := int((750 - MASK_CONTENT_WIDTH) / 2.0)
	var my := int((500 - MASK_CONTENT_HEIGHT) / 2.0)
	mask_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mask_root.offset_left = mx
	mask_root.offset_top = my
	mask_root.offset_right = mx + MASK_CONTENT_WIDTH
	mask_root.offset_bottom = my + MASK_CONTENT_HEIGHT
	var mask_tex: Texture2D
	if ResourceLoader.exists(mask_path):
		mask_tex = load(mask_path) as Texture2D
		mask_texture.texture = mask_tex
	else:
		# Create placeholder
		var placeholder_image := Image.create(MASK_CONTENT_WIDTH, MASK_CONTENT_HEIGHT, false, Image.FORMAT_RGBA8)
		placeholder_image.fill(Color.WHITE)
		mask_tex = ImageTexture.create_from_image(placeholder_image)
		mask_texture.texture = mask_tex
	
	# Create paint layer theo kích thước MaskRoot (500x280), không theo viewport
	var paint_width := MASK_CONTENT_WIDTH
	var paint_height := MASK_CONTENT_HEIGHT
	paint_image = Image.create(paint_width, paint_height, false, Image.FORMAT_RGBA8)
	paint_image.fill(Color(0, 0, 0, 0))  # Transparent

	# Restore paint layer từ GameManager nếu có
	if GameManager.decorated_mask_image and GameManager.decorated_mask_image.get_width() == paint_width and GameManager.decorated_mask_image.get_height() == paint_height:
		paint_image = GameManager.decorated_mask_image.duplicate()

	paint_image_texture = ImageTexture.create_from_image(paint_image)
	paint_texture.texture = paint_image_texture
	
	# Ensure decorations layer is on top of mask
	decorations_container.z_index = 10
	
	# Create scaled mask stencil image matching mask content size for hit testing
	var original_mask_image := mask_tex.get_image()
	mask_stencil_image = Image.create(paint_width, paint_height, false, Image.FORMAT_RGBA8)
	mask_stencil_image.fill(Color(0, 0, 0, 0))
	original_mask_image.resize(paint_width, paint_height, Image.INTERPOLATE_BILINEAR)
	mask_stencil_image.blit_rect(original_mask_image, Rect2i(0, 0, paint_width, paint_height), Vector2i(0, 0))


func _on_color_changed(c: Color) -> void:
	paint_color = c
	paint_mode = true
	eraser_mode = false
	selected_color_index = -1  # Custom color, no preset selected
	_update_color_button_highlights()
	_highlight_paint_mode()
	_update_brush_cursor()


func _highlight_paint_mode() -> void:
	# Reset emoji button highlights with proper style
	for i in range(decor_grid.get_child_count()):
		var child := decor_grid.get_child(i) as Button
		if child:
			child.modulate = Color.WHITE
			# Remove any border style
			child.remove_theme_stylebox_override("normal")
			child.remove_theme_stylebox_override("hover")
			child.remove_theme_stylebox_override("pressed")
	selected_emoji = ""
	
	# Show brush cursor in paint mode
	if brush_cursor:
		brush_cursor.visible = paint_mode and mask_canvas.get_global_rect().has_point(get_global_mouse_position())


func _populate_emoji_palette() -> void:
	selected_decor_scene = load("res://scenes/decoration_item.tscn") as PackedScene
	for emoji in EMOJI_DECORATIONS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(48, 48)
		btn.text = emoji
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_emoji_palette_item_pressed.bind(emoji))
		decor_grid.add_child(btn)


func _on_emoji_palette_item_pressed(emoji: String) -> void:
	selected_emoji = emoji
	paint_mode = false
	eraser_mode = false
	_update_color_button_highlights()
	
	# Hide brush cursor in decoration mode
	if brush_cursor:
		brush_cursor.visible = false
	
	# Visual feedback - highlight selected with yellow border
	for i in range(decor_grid.get_child_count()):
		var child := decor_grid.get_child(i) as Button
		if child:
			if i < EMOJI_DECORATIONS.size() and EMOJI_DECORATIONS[i] == emoji:
				# Yellow border for selected emoji
				child.modulate = Color(1.2, 1.2, 1.0)
				var style := StyleBoxFlat.new()
				style.bg_color = Color(1.0, 1.0, 0.9, 0.3)  # Light yellow tint
				style.border_color = Color(1.0, 0.85, 0.0)  # Yellow border
				style.set_border_width_all(3)
				style.corner_radius_top_left = 8
				style.corner_radius_top_right = 8
				style.corner_radius_bottom_left = 8
				style.corner_radius_bottom_right = 8
				child.add_theme_stylebox_override("normal", style)
				child.add_theme_stylebox_override("hover", style)
				child.add_theme_stylebox_override("pressed", style)
			else:
				child.modulate = Color.WHITE
				child.remove_theme_stylebox_override("normal")
				child.remove_theme_stylebox_override("hover")
				child.remove_theme_stylebox_override("pressed")


func _get_viewport_mouse_pos() -> Vector2:
	var pos := mask_canvas.get_local_mouse_position()
	var vp_size := sub_viewport.get_visible_rect().size
	if mask_canvas.size.x <= 0 or mask_canvas.size.y <= 0:
		return Vector2.ZERO
	var scale_x := vp_size.x / float(mask_canvas.size.x)
	var scale_y := vp_size.y / float(mask_canvas.size.y)
	var vp_pos := Vector2(pos.x * scale_x, pos.y * scale_y)
	# Dùng offset để tọa độ khớp với MaskRoot
	var mask_origin := Vector2(mask_root.offset_left, mask_root.offset_top)
	var mask_local := vp_pos - mask_origin
	return mask_local


func _input(event: InputEvent) -> void:
	# Handle painting while dragging
	if is_painting and event is InputEventMouseMotion:
		var vp_pos := _get_viewport_mouse_pos()
		_paint_line(last_paint_pos, vp_pos)
		last_paint_pos = vp_pos
	
	# Handle decoration dragging
	if _dragging_decor and event is InputEventMouseMotion:
		_update_drag_position()
	
	# Handle mouse release
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			is_painting = false
			_dragging_decor = null


func _update_drag_position() -> void:
	if not _dragging_decor:
		return
	var paint_pos := _get_viewport_mouse_pos()
	var new_pos := paint_pos + _drag_offset
	new_pos.x = clampf(new_pos.x, 0, float(MASK_CONTENT_WIDTH))
	new_pos.y = clampf(new_pos.y, 0, float(MASK_CONTENT_HEIGHT))
	_dragging_decor.position = new_pos


func _on_mask_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		var vp_pos := _get_viewport_mouse_pos()
		
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				if paint_mode:
					# Start painting
					is_painting = true
					last_paint_pos = vp_pos
					_paint_at(vp_pos)
				else:
					# Decoration mode
					_dragging_decor = _get_decoration_at(vp_pos)
					if _dragging_decor:
						_drag_offset = _dragging_decor.position - vp_pos
					elif selected_emoji != "" and selected_decor_scene:
						_place_emoji_decoration(vp_pos)
			else:
				is_painting = false
				_dragging_decor = null
		
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
			_remove_decoration_at(vp_pos)
	
	if event is InputEventMouseMotion:
		if is_painting:
			var vp_pos := _get_viewport_mouse_pos()
			_paint_line(last_paint_pos, vp_pos)
			last_paint_pos = vp_pos
		elif _dragging_decor:
			_update_drag_position()


func _is_inside_mask(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= paint_image.get_width() or y >= paint_image.get_height():
		return false
	return true  # Always allow painting for testing
	# Original code:
	#if x < 0 or y < 0 or x >= mask_stencil_image.get_width() or y >= mask_stencil_image.get_height():
	#	return false
	#var pixel := mask_stencil_image.get_pixel(x, y)
	## Check if pixel is white (paintable area) - not black outline, not transparent
	#var brightness := (pixel.r + pixel.g + pixel.b) / 3.0
	#return pixel.a > 0.5 and brightness > 0.5


func _paint_at(pos: Vector2) -> void:
	var cx := int(pos.x)
	var cy := int(pos.y)
	
	# Determine color to paint (transparent for eraser)
	var color_to_paint := paint_color
	if eraser_mode:
		color_to_paint = Color(0, 0, 0, 0)  # Transparent = erase
	
	for dx in range(-brush_size, brush_size + 1):
		for dy in range(-brush_size, brush_size + 1):
			var px := cx + dx
			var py := cy + dy
			# Circle brush
			if dx * dx + dy * dy <= brush_size * brush_size:
				if _is_inside_mask(px, py):
					paint_image.set_pixel(px, py, color_to_paint)
	
	_update_paint_texture()


func _paint_line(from: Vector2, to: Vector2) -> void:
	var distance := from.distance_to(to)
	var steps := int(distance / (brush_size * 0.5)) + 1
	
	for i in range(steps + 1):
		var t := float(i) / float(steps) if steps > 0 else 0.0
		var pos := from.lerp(to, t)
		_paint_at(pos)


func _update_paint_texture() -> void:
	paint_image_texture.update(paint_image)


func _place_emoji_decoration(pos: Vector2) -> void:
	if not selected_decor_scene or selected_emoji == "":
		return
	var inst := selected_decor_scene.instantiate()
	if inst.has_method("setup_emoji"):
		inst.setup_emoji(selected_emoji, pos, 1.0)
	else:
		inst.position = pos
	decorations_container.add_child(inst)


func _get_decoration_at(pos: Vector2) -> Node2D:
	var children := decorations_container.get_children()
	for child in children:
		if child is Node2D and child.has_method("get_rect"):
			if (child as Node2D).get_rect().has_point(pos):
				return child as Node2D
		elif child is Node2D:
			var rect := Rect2((child as Node2D).position - Vector2(24, 24), Vector2(48, 48))
			if rect.has_point(pos):
				return child as Node2D
	return null


func _remove_decoration_at(pos: Vector2) -> void:
	var child := _get_decoration_at(pos)
	if child:
		child.queue_free()


func _on_clear_pressed() -> void:
	if is_clear_animating:
		return
	is_clear_animating = true
	# Blink for 3 seconds
	# await _clear_blink_animation()
	# Clear decorations
	for child in decorations_container.get_children():
		child.queue_free()
	# Clear paint layer
	paint_image.fill(Color(0, 0, 0, 0))
	_update_paint_texture()
	# Reset button texture
	clear_button.texture_normal = clear_normal_texture
	is_clear_animating = false


func _clear_blink_animation() -> void:
	for i in range(10):
		clear_button.texture_normal = clear_hover_texture
		await get_tree().create_timer(0.15).timeout
		clear_button.texture_normal = clear_normal_texture
		await get_tree().create_timer(0.15).timeout
	clear_button.texture_normal = clear_hover_texture
	await get_tree().create_timer(0.1).timeout


func _on_done_pressed() -> void:
	if is_done_animating:
		return
	is_done_animating = true
	# Blink for 3 seconds
	# await _done_blink_animation()
	# Capture and navigate
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	var full_img := sub_viewport.get_texture().get_image()
	# Lấy vùng mask (khớp kích thước với result scene)
	var mx := int((750 - MASK_CONTENT_WIDTH) / 2.0)
	var my := int((500 - MASK_CONTENT_HEIGHT) / 2.0)
	var mask_rect := Rect2i(mx, my, MASK_CONTENT_WIDTH, MASK_CONTENT_HEIGHT)
	var img := full_img.get_region(mask_rect)
	GameManager.decorated_mask_image = paint_image.duplicate()
	GameManager.selected_face = ""
	get_tree().change_scene_to_file("res://scenes/face_selection.tscn")


func _done_blink_animation() -> void:
	for i in range(10):
		done_button.texture_normal = done_hover_texture
		await get_tree().create_timer(0.15).timeout
		done_button.texture_normal = done_normal_texture
		await get_tree().create_timer(0.15).timeout
	done_button.texture_normal = done_hover_texture
	await get_tree().create_timer(0.1).timeout
