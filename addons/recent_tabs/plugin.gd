@tool
extends EditorPlugin

const MAX_RECENT_ITEMS = 10
const color_buttons := Color8(106, 180, 255, 255)
const color_background := Color8(66, 78, 120, 128)

var editor_interface := get_editor_interface()
var script_editor := editor_interface.get_script_editor()
var script_editor_menu: Control = script_editor.get_child(0).get_child(0)
var current_editor: ScriptEditorBase

var recently_opened: Array[String] = []
var tab_bar: TabBar


func _enter_tree() -> void:
	turn_off_scripts_panel_if_on()
	
	# Wait until Godot Editor is fully loaded before continuing
	while script_editor_menu.get_children().size() < 13:
		await get_tree().process_frame
	
	# Make everything in the top bar not expand, while the tab_bar will expand
	for i in script_editor_menu.get_children():
		i.size_flags_horizontal = 0
	
	# Add tab_bar
	tab_bar = TabBar.new()
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	script_editor_menu.add_child(tab_bar)
	script_editor_menu.move_child(tab_bar, -8)
	
	tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	tab_bar.tab_clicked.connect(_on_tab_pressed)
	tab_bar.tab_close_pressed.connect(_on_tab_close_pressed)
	#extension_popup.window_input.connect(_on_recent_submenu_window_input)
	
	# Get script that is initially open
	build_recent_scripts_list()
	editing_something_new(script_editor.get_current_editor())


func _process(_delta: float) -> void:
	# This is better than "editor_script_changed" signal since it includes when you edit other files such as .cfg
	if current_editor != script_editor.get_current_editor():
		current_editor = script_editor.get_current_editor()
		editing_something_new(current_editor)
	
	var bottom_bar := get_bottom_bar()
	if is_instance_valid(bottom_bar):
		# Show bottom row only if there's an error message
		var lbl_error_message: Label = bottom_bar.get_child(1).get_child(0)
		bottom_bar.visible = (lbl_error_message.text != "")
	

func _exit_tree() -> void:
	if is_instance_valid(tab_bar):
		tab_bar.queue_free()


func build_recent_scripts_list() -> void:
	tab_bar.clear_tabs()
	for i in recently_opened.size():
		var filepath: String = recently_opened[i]
		if filepath.get_extension() == "gd":
			tab_bar.add_tab(filepath.get_file().get_basename().capitalize())
		else:
			tab_bar.add_tab(filepath.get_file())

func add_recent_script_to_array(recent_string: String) -> void:
	var find_existing: int = recently_opened.find(recent_string)
	if find_existing == -1:
		recently_opened.push_front(recent_string)
		if recently_opened.size() > MAX_RECENT_ITEMS:
			recently_opened.pop_back()
	else:
		recently_opened.push_front(recently_opened.pop_at(find_existing))


func turn_off_scripts_panel_if_on() -> void:
	var scripts_panel: Control = get_editor_interface().get_script_editor().get_child(0).get_child(1).get_child(0)
	if scripts_panel.visible == true:
		get_editor_interface().get_script_editor().get_child(0).get_child(0).get_child(0).get_popup().emit_signal("id_pressed", 14)


func editing_something_new(current_editor: ScriptEditorBase) -> void:
	if is_instance_valid(tab_bar):
		if is_instance_valid(script_editor.get_current_script()):
			add_recent_script_to_array(script_editor.get_current_script().resource_path)
			build_recent_scripts_list()


func is_main_screen_visible(screen) -> bool:
	# 0 = 2D, 1 = 3D, 2 = Script, 3 = AssetLib
	return editor_interface.get_editor_main_screen().get_child(2).visible


func get_bottom_bar() -> Control:
	var get_bottom_bar: Control = get_editor_interface().get_script_editor().get_current_editor()
	if is_instance_valid(get_bottom_bar):
		get_bottom_bar = get_bottom_bar.get_child(0)
		if is_instance_valid(get_bottom_bar):
			get_bottom_bar = get_bottom_bar.get_child(0)
			if is_instance_valid(get_bottom_bar) and get_bottom_bar.get_child_count() > 1:
				get_bottom_bar = get_bottom_bar.get_child(1)
				if is_instance_valid(get_bottom_bar):
					return get_bottom_bar
	return null


func _on_tab_close_pressed(id: int) -> void:
	recently_opened.remove_at(id)
	build_recent_scripts_list()


func _on_tab_pressed(pressed_id: int) -> void:
	var recent_string: String = recently_opened[pressed_id]
	var load_script := load(recent_string)
	if load_script != null:
		editor_interface.edit_script(load_script)
