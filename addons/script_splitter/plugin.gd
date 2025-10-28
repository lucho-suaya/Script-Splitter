@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Script Splitter
#	https://github.com/CodeNameTwister/Script-Splitter
#
#	Script Splitter addon for godot 4
#	author:		"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


const InputTool = preload("res://addons/script_splitter/core/Input.gd")
const TWISTER_script_splitter = preload("res://addons/script_splitter/core/builder.gd")
var builder : TWISTER_script_splitter = null
var handler : InputTool = null
		
var tab_container : Node = null:
	get:
		if !is_instance_valid(tab_container):
			var script_editor: ScriptEditor = EditorInterface.get_script_editor()
			tab_container = find(script_editor, "*", "TabContainer")
		return tab_container
var item_list : Node = null:
	get:
		if !is_instance_valid(item_list):
			var script_editor: ScriptEditor = EditorInterface.get_script_editor()
			item_list = find(script_editor, "*", "ItemList")
		return item_list
		
func find(root : Node, pattern : String, type : String) -> Node:
	var e : Array[Node] = root.find_children(pattern, type, true, false)
	if e.size() > 0:
		return e[0]
	return null

func _enter_tree() -> void:
	add_to_group(&"__SCRIPT_SPLITTER__")
	builder = TWISTER_script_splitter.new()
	handler = InputTool.new(self, builder)
	
func script_split() -> void:
	handler.get_honey_splitter().split()
	
func script_merge(value : Node = null) -> void:
	handler.get_honey_splitter().merge(value)
	
func _ready() -> void:
	set_process(false)
	set_process_input(false)
	for __ : int in range(5):
		await Engine.get_main_loop().process_frame
	if is_instance_valid(builder):
		builder.init_1(self, tab_container, item_list)
	if is_instance_valid(handler):
		handler.init_1()
	
	builder.connect_callbacks(
		handler.add_column, 
		handler.add_row, 
		handler.remove_column, 
		handler.remove_row,
		handler.left_tab_close,
		handler.right_tab_close,
		handler.others_tab_close
		)
	
func _save_external_data() -> void:
	builder.refresh_warnings()

func _exit_tree() -> void:
	remove_from_group(&"__SCRIPT_SPLITTER__")
	for x : Variant in [handler, builder]:
		if is_instance_valid(x) and x is Object:
			x.call(&"init_0")
			
func get_builder() -> Object:
	return builder
	
func _process(delta: float) -> void:
	builder.update(delta)
	
func _input(event: InputEvent) -> void:
	if handler.event(event):
		get_viewport().set_input_as_handled()

func _io_call(id : StringName) -> void:
	builder.handle(id)

func handle_script_drop(target_container: TabContainer, _script_idx: int, tooltip: String) -> void:
	if !is_instance_valid(builder):
		return
	
	# Create a split if there's only 1 editor container
	var source_container: TabContainer = null
	var editor_containers: Array[Node] = get_tree().get_nodes_in_group(&"__SP_EC__")
	if editor_containers.size() <= 1:
		builder.split_column()
		await get_tree().process_frame
		
		# Get the 2nd container and move back any tabs auto-added to the new split (for some reason it adds some tabs?)
		editor_containers = get_tree().get_nodes_in_group(&"__SP_EC__")
		if editor_containers.size() > 1:
			source_container = editor_containers[0].get_editor()
			target_container = editor_containers[1].get_editor()
			while target_container.get_tab_count() > 0:
				var child: Control = target_container.get_child(0)
				target_container.remove_child(child)
				source_container.add_child(child)
	
	# Move the script
	_move_script_to_split(target_container, source_container, tooltip)

func _move_script_to_split(target_container: TabContainer, source_container: TabContainer, tooltip: String) -> void:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	if !is_instance_valid(builder) or !is_instance_valid(script_editor):
		return
	
	# Find source container and source tab
	var source_tab: Control = null
	if source_container:
		source_tab = _get_source_tab(source_container, tooltip)
	else:
		for container: TabContainer in script_editor.find_children("*", "TabContainer", true, false):
			source_tab = _get_source_tab(container, tooltip)
			if source_tab:
				source_container = container
				break
	if !source_container or !source_tab or source_container == target_container:
		return
	
	# Reparent the tab to the target container and close split if source container gets empty
	source_container.remove_child(source_tab)
	target_container.add_child(source_tab)
	target_container.current_tab = target_container.get_tab_count() - 1
	if source_container.get_tab_count() == 0:
		builder.close_split(source_container)
	
	builder.trigger_metadata_update()

func _get_source_tab(source_container: TabContainer, tooltip: String) -> Control:
	for i: int in source_container.get_tab_count():
		if source_container.get_tab_tooltip(i) == tooltip:
			return source_container.get_child(i)
	return null
