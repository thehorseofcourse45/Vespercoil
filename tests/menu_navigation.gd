extends SceneTree

# Covers controller reachability of every menu. The failure this guards against is not a
# crash: focus moves, nothing happens, and the player concludes the menu is broken.
#  - A confirms and B cancels (Godot's stock ui_accept has no joypad event at all)
#  - the menu panel follows focused rows that sit below its 566 px viewport
#  - text-only screens page when the d-pad has nowhere to move focus
#  - the bestiary's lists take focus and its tabs cycle on the shoulders
#  - the atlas can be entered, picked and left with a pad

const DPAD_UP: int = JOY_BUTTON_DPAD_UP
const DPAD_DOWN: int = JOY_BUTTON_DPAD_DOWN
const PAD_A: int = JOY_BUTTON_A
const PAD_B: int = JOY_BUTTON_B
const PAD_START: int = JOY_BUTTON_START
const PAD_RB: int = JOY_BUTTON_RIGHT_SHOULDER

func _initialize() -> void:
	call_deferred("run")

func has_pad(action: String, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false

func focus_owner() -> Control:
	return root.get_viewport().gui_get_focus_owner()

func press(button: int) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = button
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = button
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame

func find_button(node: Node, title: String) -> Button:
	if node is Button and (node as Button).text.begins_with(title):
		return node
	for child in node.get_children():
		var found: Button = find_button(child, title)
		if found != null:
			return found
	return null

func run() -> void:
	var meta = root.get_node("MetaProgression")
	var runs = root.get_node("RunManager")
	meta.future_version = true # Never write the player's profile from a test.
	meta.launching = false

	# --- The bindings a pad needs to confirm anything at all ---
	assert(has_pad("ui_accept", PAD_A), "A must press the focused button")
	assert(has_pad("ui_cancel", PAD_B), "B must be able to back out")
	assert(has_pad("ui_down", DPAD_DOWN), "the d-pad drives focus through the stock ui_ actions")

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var hud = game.hud
	assert(hud.menu_kind == "title")

	# --- Title: down moves the highlight, A opens the screen it landed on ---
	assert(focus_owner() != null and focus_owner().text.begins_with("BEGIN"))
	await press(DPAD_DOWN)
	assert(focus_owner().text.begins_with("Configure"), "down should reach Configure expedition, got %s" % focus_owner().text)
	await press(PAD_A)
	assert(hud.menu_kind == "setup", "A must activate the focused button")
	find_button(hud.menu_column, "Return to title").pressed.emit()

	# --- Settings: the panel scrolls to keep the focused row visible ---
	hud.settings_menu()
	await process_frame
	var scroll := hud.menu.get_child(0) as ScrollContainer
	assert(scroll.follow_focus, "the panel must follow focus or rows vanish below it")
	# Walk to the top of the list, then back down past the bottom of the viewport: the
	# highlighted row has to stay on screen the whole way, which only happens if the
	# panel follows it.
	for i in 30:
		await press(DPAD_UP)
	assert(focus_owner() != null and scroll.get_global_rect().encloses(focus_owner().get_global_rect()), "the focused row must stay inside the panel")
	for i in 30:
		await press(DPAD_DOWN)
	assert(scroll.scroll_vertical > 0, "a list longer than the panel must scroll as focus moves down")
	assert(scroll.get_global_rect().encloses(focus_owner().get_global_rect()), "and the row it lands on must be visible")
	assert(hud.menu_kind == "settings")

	# --- Field guide: text only, so paging replaces focus travel ---
	hud.codex(false)
	scroll = hud.menu.get_child(0) as ScrollContainer
	await process_frame
	var before: int = scroll.scroll_vertical
	await press(DPAD_DOWN)
	assert(scroll.scroll_vertical > before, "a text screen must page when the d-pad has nowhere to go")

	# --- Bestiary: tabs on the shoulders, lists take focus and scroll themselves ---
	hud.bestiary(false)
	assert(hud.menu_tabs != null and hud.menu_tabs.get_tab_count() == 3)
	assert(hud.menu_tabs.current_tab == 0)
	await press(PAD_RB)
	assert(hud.menu_tabs.current_tab == 1, "RB should reach the elite tab")
	await press(JOY_BUTTON_LEFT_SHOULDER)
	assert(hud.menu_tabs.current_tab == 0, "LB should come back")
	var list := hud.menu_tabs.get_child(0) as ScrollContainer
	assert(list.focus_mode == Control.FOCUS_ALL, "the list needs focus or a pad can never scroll it")
	await process_frame
	assert(list.get_v_scroll_bar().max_value > list.size.y, "the common list must overflow its frame for this to prove anything")
	list.grab_focus()
	await process_frame
	var inner: int = list.scroll_vertical
	await press(DPAD_DOWN)
	assert(list.scroll_vertical > inner, "a focused list should scroll on the d-pad")

	# --- Atlas: reachable, choosable and escapable without a mouse ---
	hud.title_screen()
	hud.open_atlas()
	await process_frame
	assert(hud.atlas.visible)
	await press(PAD_A)
	assert(not hud.atlas.visible, "A must pick the highlighted ground")

	hud.open_atlas()
	await process_frame
	assert(hud.atlas.visible)
	await press(PAD_START)
	assert(not hud.atlas.visible, "Start must leave the atlas instead of stranding the player")

	# --- Pause: B resumes a live run ---
	runs.start()
	hud.pause_menu()
	await process_frame
	assert(hud.menu.visible and root.get_tree().paused)
	await press(PAD_B)
	assert(not hud.menu.visible, "B should back out of a menu")
	assert(not paused, "and the run should resume")

	print("MENU NAVIGATION PASS: pad confirms, backs out, follows focus, pages text, cycles tabs and drives the atlas")
	quit()
