@tool
extends TabContainer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const Dottab = preload("res://addons/script_splitter/core/ui/splitter/taby/dottab.gd")
const CLOSE = preload("res://addons/script_splitter/assets/Close.svg")

const GLOBALS : PackedStringArray = ["_GlobalScope", "_GDScript"]

#
signal focus(o : TabContainer, index : int)
signal remove(o : TabContainer, index : int)
	
var _new_tab_settings : bool = false
var _tab_queue : int = -1
var _tab_drag_started: bool = false
var _dragged_tab: Control = null

func _enter_tree() -> void:
	add_to_group(&"__SC_SPLITTER__")
	
func _exit_tree() -> void:
	if is_in_group(&"__SC_SPLITTER__"):
		remove_from_group(&"__SC_SPLITTER__")

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	
	var tb : TabBar = get_tab_bar()
	if tb:
		tb.auto_translate_mode = auto_translate_mode
	
	drag_to_rearrange_enabled = true

	#CONNECT
	var tab : TabBar = get_tab_bar()
	tab.set_script(Dottab)
	tab.tab_selected.connect(_on_selected)
	
	tab.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	tab.tab_close_pressed.connect(_on_remove)
	tab.select_with_rmb = true
	tab.on_start_drag.connect(on_drag)
	tab.on_stop_drag.connect(out_drag)

func _set_tab() -> void:
	if current_tab != _tab_queue and _tab_queue > -1 and _tab_queue < get_tab_count():
		current_tab = _tab_queue
	_new_tab_settings = false
	
func set_tab(index : int) -> void:
	if index > -1 and index < get_tab_count():
		_tab_queue = index
	
	if _new_tab_settings:
		return
		
	_new_tab_settings = true
	_set_tab.call_deferred()
	
func on_drag(tab : TabBar) -> void:
	for x : Node in tab.get_tree().get_nodes_in_group(&"ScriptSplitter"):
		if x.has_method(&"dragged"):
			x.call(&"dragged", tab, true)
	
func out_drag(tab : TabBar) -> void:
	for x : Node in tab.get_tree().get_nodes_in_group(&"ScriptSplitter"):
		if x.has_method(&"dragged"):
			x.call(&"dragged", tab, false)

func _on_remove(index : int) -> void:
	remove.emit(self, index)
	
func _on_selected(value : int) -> void:
	focus.emit(self, value)

func get_root() -> Node:
	return self

func set_item_tooltip(idx : int, txt : String) -> void:
	if idx > -1 and get_tab_count() > idx:
		set_tab_tooltip(idx, txt)
	
func set_item_text(idx : int, txt : String) -> void:
	if idx > -1 and get_tab_count() > idx:
		set_tab_title(idx, txt)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var editor_containers: Array[Node] = get_tree().get_nodes_in_group(&"__SP_EC__")
		if editor_containers.size() <= 1 and current_tab >= 0 and current_tab < get_tab_count():
			_tab_drag_started = true
			_dragged_tab = get_tab_control(current_tab)
	elif what == NOTIFICATION_DRAG_END:
		if !_tab_drag_started:
			return
		
		# Check if dropped below tabs and not on tabs and call plugin to handle script drag
		_tab_drag_started = false
		var mouse_pos: Vector2 = get_global_mouse_position()
		if get_global_rect().has_point(mouse_pos) and (mouse_pos.y - get_global_rect().position.y) > 75.0:
			var script_splitters: Array[Node] = get_tree().get_nodes_in_group(&"__SCRIPT_SPLITTER__")
			if script_splitters.size() > 0:
				script_splitters[0].call(&"on_tab_script_drag", self, _dragged_tab)
		
		_dragged_tab = null
