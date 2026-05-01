extends Node2D

const SCALE = 160.0
const SIDE_CM = 3.0

var tri = []
var prism_h_cm
var ray_h_cm

# 可调节参数
var n_in = 1.0      # 外部折射率
var n_out = 1.5     # 棱镜折射率
var incident_angle_deg = -30.0  # 入射角（度），默认30°

# 存储追踪数据
var trace_data = {
	"entry_dist_to_bottom": 0.0,
	"incident_angle": 0.0,
	"middle_angle": 0.0,
	"exit_angle": 0.0,
	"exit_dist_to_nearest": 0.0,
}

# UI 控件
var n_in_input: LineEdit
var n_out_input: LineEdit
var angle_input: LineEdit
var height_slider: HSlider
var n_in_label: Label
var n_out_label: Label
var angle_label: Label
var height_label: Label

func _ready():
	prism_h_cm = SIDE_CM * sqrt(3.0) / 2.0
	ray_h_cm = prism_h_cm / 2.0
	build_prism()
	create_ui()
	queue_redraw()

func create_ui():
	var start_y = 100
	var line_height = 35
	var input_width = 100
	var label_width = 120
	
	# N_IN (external refractive index)
	n_in_label = Label.new()
	n_in_label.text = "air n:"
	n_in_label.position = Vector2(20, start_y)
	n_in_label.add_theme_color_override("font_color", Color.WHITE)
	n_in_label.add_theme_font_size_override("font_size", 16)
	add_child(n_in_label)
	
	n_in_input = LineEdit.new()
	n_in_input.text = str(n_in)
	n_in_input.position = Vector2(20 + label_width, start_y)
	n_in_input.size = Vector2(input_width, 30)
	n_in_input.text_submitted.connect(_on_n_in_submitted)
	n_in_input.focus_exited.connect(_on_n_in_focus_exited)
	add_child(n_in_input)
	
	# N_OUT (prism refractive index)
	n_out_label = Label.new()
	n_out_label.text = "prism n"
	n_out_label.position = Vector2(20, start_y + line_height)
	n_out_label.add_theme_color_override("font_color", Color.WHITE)
	n_out_label.add_theme_font_size_override("font_size", 16)
	add_child(n_out_label)
	
	n_out_input = LineEdit.new()
	n_out_input.text = str(n_out)
	n_out_input.position = Vector2(20 + label_width, start_y + line_height)
	n_out_input.size = Vector2(input_width, 30)
	n_out_input.text_submitted.connect(_on_n_out_submitted)
	n_out_input.focus_exited.connect(_on_n_out_focus_exited)
	add_child(n_out_input)
	
	# Incident angle
	angle_label = Label.new()
	angle_label.text = "θ1:"
	angle_label.position = Vector2(20, start_y + line_height * 2)
	angle_label.add_theme_color_override("font_color", Color.WHITE)
	angle_label.add_theme_font_size_override("font_size", 16)
	add_child(angle_label)
	
	angle_input = LineEdit.new()
	angle_input.text = str(-incident_angle_deg)
	angle_input.position = Vector2(20 + label_width, start_y + line_height * 2)
	angle_input.size = Vector2(input_width, 30)
	angle_input.text_submitted.connect(_on_angle_submitted)
	angle_input.focus_exited.connect(_on_angle_focus_exited)
	add_child(angle_input)
	
	# Ray height slider
	height_label = Label.new()
	height_label.text = "Ray Height"
	height_label.position = Vector2(20, start_y + line_height * 3 + 5)
	height_label.add_theme_color_override("font_color", Color.WHITE)
	height_label.add_theme_font_size_override("font_size", 16)
	add_child(height_label)
	
	height_slider = HSlider.new()
	height_slider.min_value = 0.02
	height_slider.max_value = prism_h_cm - 0.02
	height_slider.step = 0.01
	height_slider.value = ray_h_cm
	height_slider.size = Vector2(220, 30)
	height_slider.position = Vector2(20, start_y + line_height * 3 + 25)
	height_slider.value_changed.connect(_on_height_changed)
	add_child(height_slider)

func _on_n_in_submitted(text: String):
	_update_n_in(text)
	n_in_input.release_focus()

func _on_n_in_focus_exited():
	_update_n_in(n_in_input.text)

func _update_n_in(text: String):
	if text.is_valid_float():
		var val = text.to_float()
		if val > 0:
			n_in = val
		else:
			n_in_input.text = str(n_in)
	else:
		n_in_input.text = str(n_in)
	queue_redraw()

func _on_n_out_submitted(text: String):
	_update_n_out(text)
	n_out_input.release_focus()

func _on_n_out_focus_exited():
	_update_n_out(n_out_input.text)

func _update_n_out(text: String):
	if text.is_valid_float():
		var val = text.to_float()
		if val > 0:
			n_out = val
		else:
			n_out_input.text = str(n_out)
	else:
		n_out_input.text = str(n_out)
	queue_redraw()

func _on_angle_submitted(text: String):
	_update_angle(text)
	angle_input.release_focus()

func _on_angle_focus_exited():
	_update_angle(angle_input.text)

func _update_angle(text: String):
	
	if text.is_valid_float():
		if text.to_float() > 89:
			incident_angle_deg = 89
			angle_input.text = "89"
		elif text.to_float() < 0:
			incident_angle_deg = 0
			angle_input.text = "0"
		else:
			incident_angle_deg = -text.to_float()
			angle_input.text = str(-incident_angle_deg)
	else:
		angle_input.text = str(-incident_angle_deg)
	queue_redraw()

func _on_height_changed(value: float):
	ray_h_cm = value
	height_label.text = "Ray Height"
	queue_redraw()

func _process(delta):
	pass

func build_prism():
	var side = SIDE_CM * SCALE
	var h = prism_h_cm * SCALE
	var c = Vector2(700, 430)
	
	tri = [
		c + Vector2(0, -2*h/3),      # Top vertex
		c + Vector2(-side/2, h/3),   # Bottom-left vertex
		c + Vector2(side/2, h/3)     # Bottom-right vertex
	]

func _draw():
	draw_polygon(tri, [Color(0.2, 0.6, 1, 0.22)])
	
	for i in range(3):
		draw_line(tri[i], tri[(i+1)%3], Color.WHITE, 3)
	
	trace_ray()
	draw_data_panel()

func trace_ray():
	# 计算左斜面的法线（指向外部）
	var left_edge = tri[0] - tri[1]  # 从左下角到顶点的边
	var left_normal = Vector2(-left_edge.y, left_edge.x).normalized()
	# 确保法线指向外部（左侧）
	if left_normal.x > 0:
		left_normal = -left_normal
	
	# 根据入射角和高度计算光线
	var incident_rad = deg_to_rad(incident_angle_deg)
	
	# 法线反方向（垂直入射时的方向）
	var base_dir = -left_normal
	
	# 旋转入射角来得到实际光线方向
	# 正角度使光线向下偏转
	var incident_dir = base_dir.rotated(incident_rad)
	
	# 根据高度计算入射点在左斜面上的位置
	var top_y = tri[0].y
	var entry_y = top_y + ray_h_cm * SCALE
	
	# 计算该高度在左斜面上的x坐标
	# 左斜面从 tri[1] (左下角) 到 tri[0] (顶点)
	var t = (entry_y - tri[1].y) / (tri[0].y - tri[1].y)
	var entry_x = tri[1].x + t * (tri[0].x - tri[1].x)
	var entry_point_on_edge = Vector2(entry_x, entry_y)
	
	# 从入射点沿着入射方向的反方向延伸一段距离作为起点
	var start = entry_point_on_edge - incident_dir * 300
	
	var dir = incident_dir
	var current_n = n_in
	var pos = start
	
	# Reset trace data
	trace_data = {
		"entry_dist_to_bottom": 0.0,
		"incident_angle": 0.0,
		"middle_angle": 0.0,
		"exit_angle": 0.0,
		"exit_dist_to_nearest": 0.0,
	}
	
	var entry_point = null
	var entry_normal = null
	var exit_point = null
	var exit_normal = null
	var middle_dir = null
	var final_dir = null
	var pre_incident_dir = null
	
	for bounce in range(3):
		var hit = find_hit(pos, dir)
		
		if hit == null:
			draw_line(pos, pos + dir * 2000, Color.YELLOW, 3)
			if exit_point == null and entry_point != null:
				final_dir = dir
			break
		
		draw_line(pos, hit.point, Color.YELLOW, 3)
		
		var next_n = n_out if current_n == n_in else n_in
		
		# Entry point (external -> prism)
		if current_n == n_in and next_n == n_out:
			if entry_point == null:
				entry_point = hit.point
				entry_normal = hit.normal
				
				# Draw normal at entry point
				draw_line(entry_point, entry_point + entry_normal * 180, Color.CYAN, 2)
				draw_line(entry_point, entry_point - entry_normal * 180, Color.CYAN, 1)
				
				var dist_to_bottom_left = entry_point.distance_to(tri[1]) / SCALE
				var dist_to_bottom_right = entry_point.distance_to(tri[2]) / SCALE
				trace_data["entry_dist_to_bottom"] = min(dist_to_bottom_left, dist_to_bottom_right)
		
		# Exit point (prism -> external)
		elif current_n == n_out and next_n == n_in:
			if exit_point == null:
				exit_point = hit.point
				exit_normal = hit.normal
				pre_incident_dir = dir
				
				# Draw normal at exit point
				draw_line(exit_point, exit_point + exit_normal * 180, Color.ORANGE, 2)
				draw_line(exit_point, exit_point - exit_normal * 180, Color.ORANGE, 1)
				
				var nearest_dist = INF
				for corner in tri:
					var d = exit_point.distance_to(corner) / SCALE
					if d < nearest_dist:
						nearest_dist = d
				trace_data["exit_dist_to_nearest"] = nearest_dist
		
		var new_dir = refract(dir, hit.normal, current_n, next_n)
		
		if new_dir == null:
			new_dir = dir.bounce(hit.normal).normalized()
		
		if entry_point != null and exit_point == null:
			middle_dir = new_dir
		
		pos = hit.point + new_dir * 0.5
		dir = new_dir
		current_n = next_n
	
	if final_dir == null and dir != incident_dir:
		final_dir = dir
	
	# Calculate angles
	if entry_point != null and entry_normal != null:
		trace_data["incident_angle"] = calc_angle_between(incident_dir, entry_normal)
		
		if middle_dir != null:
			trace_data["middle_angle"] = calc_angle_between(middle_dir, -entry_normal)
	
	if exit_point != null and exit_normal != null and final_dir != null:
		trace_data["exit_angle"] = calc_angle_between(final_dir, exit_normal)
	elif exit_point != null and exit_normal != null and pre_incident_dir != null:
		trace_data["exit_angle"] = calc_angle_between(pre_incident_dir, -exit_normal)
	
	draw_line(pos, pos + dir * 2000, Color.YELLOW, 3)

func calc_angle_between(dir1, dir2):
	var d1 = dir1.normalized()
	var d2 = dir2.normalized()
	var dot = d1.dot(d2)
	dot = clamp(dot, -1.0, 1.0)
	var angle = acos(abs(dot))
	return rad_to_deg(angle)

func find_hit(start, dir):
	var best_d = INF
	var result = null
	
	for i in range(3):
		var a = tri[i]
		var b = tri[(i+1)%3]
		
		var intersection = Geometry2D.segment_intersects_segment(
			start, start + dir * 4000, a, b
		)
		
		if intersection != null and intersection is Vector2:
			var p = intersection
			var d = start.distance_to(p)
			if d > 0.5 and d < best_d:
				best_d = d
				var edge = (b - a).normalized()
				var n = Vector2(-edge.y, edge.x).normalized()
				if n.dot(dir) > 0:
					n = -n
				result = {"point": p, "normal": n}
	
	return result

func refract(I, N, n1, n2):
	I = I.normalized()
	N = N.normalized()
	
	var r = n1 / n2
	var cos_i = -N.dot(I)
	var sin_t2 = r * r * (1.0 - cos_i * cos_i)
	
	if sin_t2 > 1.0:
		return null
	
	var cos_t = sqrt(1.0 - sin_t2)
	return (r * I + (r * cos_i - cos_t) * N).normalized()

func draw_data_panel():
	var font_size = 18
	var start_x = 20
	var start_y = 20
	var line_height = 28
	
	var y = start_y
	
	# 1. Entry point distance to nearest bottom corner
	draw_string(ThemeDB.fallback_font, 
		Vector2(start_x, y), 
		"Entry to bottom corner: %.2f cm" % trace_data["entry_dist_to_bottom"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	y += line_height
	
	# 2. Three angles
	draw_string(ThemeDB.fallback_font,
		Vector2(start_x, y),
		"Incident: %.1f°  |  Refracted: %.1f°  |  Exit: %.1f°" % [
			trace_data["incident_angle"],
			trace_data["middle_angle"],
			trace_data["exit_angle"]
		],
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	y += line_height
	
	# 3. Exit point distance to nearest corner
	draw_string(ThemeDB.fallback_font,
		Vector2(start_x, y),
		"Exit to nearest corner: %.2f cm" % trace_data["exit_dist_to_nearest"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func deg_to_rad(deg):
	return deg * PI / 180.0

func rad_to_deg(rad):
	return rad * 180.0 / PI
