extends Node

onready var _stc = get_node("SceneTreeControl")
onready var _save_dialog = get_node("SaveDialog")
onready var _load_dialog = get_node("LoadDialog")
onready var _preview_dialog = get_node("PreviewDialog")

export(PackedScene) var _scene = null
export(int, 1, 200, 1) var _fps = 30
export(float, 0.01, 100, 0.01) var _duration = 2.0
export(Vector2) var _size = Vector2(128,128)
export(Vector2) var _offset = Vector2(0,0)
export(int, 1, 1000, 1) var _cols = 4
export(int, 0, 1000, 1) var _frame_delay = 0

var _captures = []
var _img = null
var _frame = 0
var _frame_offset = 0
var _capturing = false
var _file = null
var _timer = 0.0

func _ready():
	get_node("Tools/Split/Log").set_scroll_follow(true)
	set_process(false)
	_save_dialog.connect("file_selected", self, "_save_file")
	_load_dialog.connect("file_selected", self, "_load_file")
	_stc.set_size(_size)
	_update_math()

func load_scene():
	if _capturing:
		return
	var scene
	if _scene != null and _scene.can_instance():
		scene = _scene.instance()
	else:
		scene = Particles2D.new()
		scene.process_material = ParticlesMaterial.new()
		scene.set_scale(Vector2(10,10))

	var node = Node2D.new()
	node.add_child(scene)
	node.set_position(_size/2 + _offset)
	print(_offset)
	print(node.get_position())
	_stc.load_scene(node)

func start_capture():
	load_scene()
	_frame_offset = 0
	_capturing = true
	_img = null
	_captures = []
	_frame = 0
	_log_msg("Started capturing")
	set_process(true)
	_stc.start()

func end_capture():
	_stc.stop()
	set_process(false)
	var y_size = ceil(float(_captures.size())/_cols) * _size.y
	var x_size = ceil(_cols * _size.x)
	_img = Image.new()
	_img.create(x_size, y_size, false, _captures[0].get_format())
	var r = 0
	var c = 0
	for i in range(0, _captures.size()):
		_img.blit_rect(_captures[i], Rect2(Vector2(0,0),_size), Vector2(c*_size.x,r*_size.y))
		c += 1
		if c >= _cols:
			c = 0
			r += 1
	var tex = ImageTexture.new()
	tex.create_from_image(_img, 0)
	get_node("Tools/Split/Box/PreviewImage").set_texture(tex)
	_capturing = false
	_log_msg("Finished capturing, image size: %d, %d" % [_img.get_width(), _img.get_height()])

func _process(delta):
	_timer += delta
	if _timer < 1.0/_fps:
		return
	else:
		_timer -= 1.0/_fps
	_frame_offset += 1
	if _frame_offset <= _frame_delay:
		_stc.get_sub_tree().iteration(1.0/_fps)
		_stc.get_sub_tree().idle(1.0/_fps)
		return
	capture_frame(1.0/_fps)
	if _frame >= _fps * _duration:
		end_capture()

func capture_frame(delta_step):
	_stc.get_sub_tree().iteration(delta_step)
	_stc.get_sub_tree().idle(delta_step)
	VisualServer.draw()
	_captures.append(_stc.get_image())
	_log_msg("Captured frame: %03d" % _frame)
	_frame += 1

func _log_msg(msg):
	get_node("Tools/Split/Log").add_text(msg + "\n")

func _show_alert(msg):
	_log_msg(msg)
	get_node("AcceptDialog").set_text(msg)
	get_node("AcceptDialog").show_modal(true)

func _update_math():
	var tot = round(_duration * _fps)
	var rows = ceil(float(tot)/_cols)
	var left = int(tot) % int(_cols)
	if left != 0:
		left = int(_cols) - left
	get_node("Tools/Split/Box/Math").set_text("Total frames: %d\nSize: %d, %d\nRows: %d\nCols: %d\nEmpty: %d" % [tot, _size.x*_cols, _size.y*rows, rows, _cols, left])

func _on_load_scene_pressed():
	if _capturing:
		_show_alert("Unable to load, still recording")
		return
	_load_dialog.show_modal(true)
	_load_dialog.invalidate()

func _load_file(file):
	_file = file
	var scene = ResourceLoader.load(file, "", true)
	if scene != null and scene.has_method("can_instance") and scene.can_instance():
		_scene = scene
		load_scene()
		_log_msg("Loaded scene at:\n%s" % file)
	else:
		_show_alert("Unable to load scene at:\n%s" % file)

func _reload():
	if _file != null:
		_load_file(_file)

func _on_save_pressed():
	if _capturing or _img == null:
		_show_alert("Unable to save, image not ready")
		return
	_save_dialog.show_modal(true)
	_save_dialog.invalidate()

func _save_file(file):
	if _capturing or _img == null:
		_show_alert("Unable to save, image not ready")
		return
	_img.save_png(file)
	_log_msg("Saved image to file: %s" % file)

func _on_generate_pressed():
	if _capturing:
		return
	start_capture()

func _on_previewImage_input_event( ev ):
	if _img == null: return
	if ev is InputEventMouseButton and ev.button_index == BUTTON_LEFT and ev.is_pressed() and not ev.is_echo():
		var tex = ImageTexture.new()
		tex.create_from_image(_img, 0)
		get_node("PreviewDialog/TextureFrame").set_texture(tex)
		_preview_dialog.show_modal(false)

func _on_duration_value_changed(value):
	_duration = value
	_update_math()

func _on_fps_value_changed(value):
	_fps = value
	_update_math()

func _on_cols_value_changed(value):
	_cols = value
	_update_math()

func _on_x_size_value_changed(value):
	_size.x = value
	_stc.set_size(_size)
	_update_math()
	_reload()

func _on_y_size_value_changed(value):
	_size.y = value
	_stc.set_size(_size)
	_update_math()
	_reload()

func _on_reference_color_changed( color ):
	_stc.set_reference_color(color)

func _on_frame_delay_value_changed( value ):
	_frame_delay = value

func _on_offset_YVal_value_changed( value ):
	_offset.y = value
	_reload()

func _on_offset_XVal_value_changed( value ):
	_offset.x = value
	_reload()
