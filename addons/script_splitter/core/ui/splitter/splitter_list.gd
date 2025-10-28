@tool
extends ItemList
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

var _ss: Callable
var _delta : int = 0
var _list : ItemList = null
var _dragging: bool = false
var _drag_data: Dictionary = {}

func _ready() -> void:
	set_physics_process(false)

func update() -> void:
	_delta = 0
	set_physics_process(true)
	
func set_list(item : ItemList) -> void:
	_list = item

func set_reference(scall : Callable) -> void:
	_ss = scall
	
func changes(list : ItemList) -> bool:
	if list.item_count != item_count:
		return true
		
	for x : int in list.item_count:
		if is_selected(x) != is_selected(x) or \
		get_item_text(x) != list.get_item_text(x) or\
		get_item_icon(x) != list.get_item_icon(x) or \
		get_item_icon_modulate(x) != list.get_item_icon_modulate(x) or \
		get_item_tooltip(x) != list.get_item_tooltip(x):
			return true
			
	return false
	
func _physics_process(__ : float) -> void:
	_delta += 1
	if _delta < 10:
		return
	set_physics_process(false)
	if !_ss.is_valid():
		return
	if !changes(_list):
		return
	_ss.call()
	
func _get_drag_data(at_position: Vector2) -> Variant:
	var item_idx: int = get_item_at_position(at_position, true)
	if item_idx == -1:
		return null
	
	var preview: Label = Label.new()
	preview.text = get_item_text(item_idx)
	set_drag_preview(preview)
	
	_dragging = true
	_drag_data = { "type": "script_file", "index": item_idx, "tooltip": get_item_tooltip(item_idx), "text": preview.text }
	return _drag_data
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if _dragging:
			_handle_drag_end()
		_dragging = false
		_drag_data = {}
	
func _handle_drag_end() -> void:
	# If we're over an editor container, call plugin to handle script drop
	var mouse_pos: Vector2 = get_global_mouse_position()
	for editor_container: Node in get_tree().get_nodes_in_group(&"__SP_EC__"):
		if !is_instance_valid(editor_container):
			continue
		if !editor_container.get_editor() or !editor_container.get_global_rect().has_point(mouse_pos):
			continue
		for node in get_tree().get_nodes_in_group(&"__SCRIPT_SPLITTER__"):
			node.call(&"handle_script_drop", editor_container.get_editor(), _drag_data["index"], _drag_data["tooltip"])
			return


#
#var dragged_item_index: int = -1
#
#func _get_drag_data(at_position: Vector2) -> Variant:
	#var item_index = get_item_at_position(at_position)
#
	#if item_index != -1:
		#dragged_item_index = item_index
		#
		#var drag_preview : Label = Label.new()
		#drag_preview.text = get_item_text(item_index)
		#set_drag_preview(drag_preview)
		#
		#return item_index
	#return null
#
#func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	#if typeof(data) == TYPE_INT:
		#var drop_index : int = get_item_at_position(at_position)
		#
		#return drop_index != -1 and drop_index != data
		#
	#return false
#
#func _drop_data(at_position: Vector2, data: Variant) -> void:
	#if !(data is int):
		#return
	#var from_index : int = data as int
	#
	#var to_index : int = get_item_at_position(at_position)
	#
	#if from_index != -1 and to_index != -1:
		#_list.move_item(from_index, to_index)
	#
	#dragged_item_index = -1
