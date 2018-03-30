extends Panel

var _selected = true
var _tex = null
var _tree = null
var _size = Vector2(128,128)
var _color = Color(1,0,0,1)

onready var _ViewportSprite = $Control/ViewportSprite

func get_sub_tree():
	return _tree

func _draw():
	var pos = (get_rect().size - _size) / 2
	draw_rect(Rect2(pos.x,pos.y,_size.x,_size.y), _color)

func set_reference_color(color):
	_color = color
	update()

func set_size(size):
	_size = size
	update()

func load_scene(scene, singletons=[]):
	if _tree != null:
		_tree.finish()
	_tree = SceneTree.new()
	_tree.init()
	_tree.get_root().render_target_v_flip = true
	_tree.get_root().set_attach_to_screen_rect(Rect2(Vector2(), Vector2()))
	_tree.get_root().set_size(_size)
	_tree.get_root().set_size_override(true, _size, Vector2(0,0))
	_tree.get_root().render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	_tex = _tree.get_root().get_texture()

	for s in singletons:
		_tree.get_root().add_child(s)
	_tree.get_root().add_child(scene)
	scene.get_viewport().set_transparent_background(true)

	_ViewportSprite.set_texture(_tex)
	_tree.paused = true
	update()

func start():
	_tree.paused = false

func stop():
	_tree.paused = true

func get_image():
	return _ViewportSprite.texture.get_data()

func _exit_tree():
	if _tree != null:
		_tree.finish()