extends Control

var brush_size := 15.0
var brush_color := Color(1.0, 0.5, 0.7, 0.6)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100


func _process(_delta: float) -> void:
	# Follow mouse position
	var mouse_pos := get_global_mouse_position()
	global_position = mouse_pos - Vector2(brush_size, brush_size)
	queue_redraw()


func _draw() -> void:
	# Draw brush preview circle
	var center := Vector2(brush_size, brush_size)
	
	# Draw filled circle with transparency
	draw_circle(center, brush_size, Color(brush_color.r, brush_color.g, brush_color.b, 0.3))
	
	# Draw outline
	var outline_color := Color(brush_color.r, brush_color.g, brush_color.b, 0.8)
	var points := PackedVector2Array()
	var point_count := 32
	for i in range(point_count + 1):
		var angle := (float(i) / float(point_count)) * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * brush_size)
	
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], outline_color, 2.0, true)


func set_brush_size(new_size: float) -> void:
	brush_size = new_size
	custom_minimum_size = Vector2(new_size * 2, new_size * 2)
	queue_redraw()


func set_brush_color(color: Color) -> void:
	brush_color = color
	queue_redraw()
