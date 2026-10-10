extends SceneTree
# The ADMIN CONSOLE must fit its own panel and must not be covered by the notice
# banner, on the FIRST open -- not only after an action rebuilds it. Both bugs
# only showed on that first open, which is why the handlers-only suite missed
# them. Run: godot --headless --path C:/Godot/Vespercoil --script tests/admin_panel.gd
var game
var meta

func _initialize() -> void:
	call_deferred("run")

func buttons(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Button:
			out.append(child.text)
		buttons(child, out)

func find_button(node: Node, needle: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text.to_lower().contains(needle.to_lower()):
			return child
		var found := find_button(child, needle)
		if found != null:
			return found
	return null

func panel_height(hud) -> float:
	return hud.menu_column.get_combined_minimum_size().y

func hotkey_open(hud) -> void:
	var hotkey := InputEventKey.new()
	hotkey.keycode = KEY_A
	hotkey.ctrl_pressed = true
	hotkey.shift_pressed = true
	hotkey.pressed = true
	hud._input(hotkey)

# The console must be openable again after EVERY way of closing it, not just the
# one path the reporter happened to use. Each case closes then reopens by hotkey
# and asserts the console is actually on screen.
func reopen_cycles(hud, tag: String) -> void:
	for i in 3:
		assert(hud.menu_kind == "admin" and hud.menu.visible, "%s cycle %d: console did not reopen (kind=%s vis=%s)" % [tag, i, hud.menu_kind, str(hud.menu.visible)])
		var height: float = panel_height(hud)
		assert(height <= EXPECTED_MAX, "%s cycle %d: reopened at %.0fpx" % [tag, i, height])
		close_for(hud, tag)
		await process_frame
			# The console is dismissed. The MENU need not hide: Return from a console
		# opened over the pause menu correctly goes back to the pause menu, so
		# menu.visible stays true on purpose. What must never happen is the console
		# itself still being up.
		assert(hud.menu_kind != "admin", "%s cycle %d: console still open after closing" % [tag, i])
		hotkey_open(hud)
		await process_frame
	
func close_for(hud, tag: String) -> void:
	match tag:
		"return":
			var back := find_button(hud.menu, "Return")
			assert(back != null, "no Return button")
			back.pressed.emit()
		"hotkey":
			hotkey_open(hud)
		"escape":
			press_escape(hud)
		_:
			assert(false, "unknown close path %s" % tag)

func close_for_escape() -> InputEventKey:
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	return esc

# ESC is handled in _unhandled_input, NOT _input (which only owns the admin
# hotkey), so it has to go through the right handler or the check tests nothing.
func press_escape(hud) -> void:
	hud._unhandled_input(close_for_escape())

# The console is 15 buttons + 6 text lines after the run controls were added, so
# it is EXPECTED to exceed one screen -- what it must NOT do is overflow without
# the scroll container being able to reach the bottom, or change size when a
# control is pressed.
const EXPECTED_MAX := 1400.0

func run() -> void:
	meta = root.get_node("MetaProgression")
	meta.future_version = true
	meta.launching = false
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	meta.launching = true
	meta.settings["pause"] = false
	var hud = game.hud
	hud.restart()
	await process_frame
	await process_frame
	game = current_scene
	hud = game.hud
	game.director.set_physics_process(false)
	game.player.invulnerability = 9999

	# Open from the PAUSE menu, which is the state that used to overflow.
	hud.pause_menu()
	await process_frame
	var hotkey := InputEventKey.new()
	hotkey.keycode = KEY_A
	hotkey.ctrl_pressed = true
	hotkey.shift_pressed = true
	hotkey.pressed = true
	hud._input(hotkey)
	assert(hud.menu_kind == "admin", "hotkey did not open the admin console")
	await process_frame
	var first: float = panel_height(hud)
	print("ADMIN first open: %.0fpx content" % first)
	assert(first <= EXPECTED_MAX, "admin console overflows on first open: %.0fpx (max %.0f)" % [first, EXPECTED_MAX])

	# The notice banner is inside the console's rect; it must not be on screen.
	# Guardian spawn is the action that fires one.
	hud.notice_panel.show()
	hud.notices.append({"title": "x", "detail": "y", "color": Color.RED})
	var spawned := find_button(hud.menu, "spawn this ground's guardian")
	assert(spawned != null, "no guardian button")
	spawned.pressed.emit()
	await process_frame
	assert(not hud.notice_panel.visible, "notice banner covers the admin console")
	assert(hud.notices.is_empty(), "stale notice queued behind the console: %d" % hud.notices.size())
	assert(panel_height(hud) <= EXPECTED_MAX, "console overflowed after spawn: %.0f" % panel_height(hud))

	# Every action must leave the console the same height it opened at.
	var baseline: float = panel_height(hud)
	for needle in ["god mode", "restore full health", "1,000 run gold", "clear all enemies", "unlock all",
			"advance the clock", "level up once", "kill all non-elite", "every weapon in the vault",
			"every passive", "trinket slots", "active ability"]:
		var b := find_button(hud.menu, needle)
		assert(b != null, "missing control: %s" % needle)
		b.pressed.emit()
		await process_frame
		assert(find_button(hud.menu, needle) != null, "%s vanished after pressing itself" % needle)
		var now: float = panel_height(hud)
		assert(now <= EXPECTED_MAX, "%s left the console at %.0fpx" % [needle, now])
		assert(is_equal_approx(now, baseline), "%s changed the console height: %.0f -> %.0f" % [needle, baseline, now])
		assert(not hud.notice_panel.visible, "%s re-showed the notice banner" % needle)
	# The new controls must have actually done their work, not just rendered.
	assert(arsenal_check(game), "the vault/passive/trinket controls did not change the loadout")

	# The reported break: close the console once and it could never be reopened.
	# Every close path gets its own open/close/open/close/open cycle.
	await reopen_cycles(hud, "return")
	await reopen_cycles(hud, "hotkey")
	# Escape while the console is open, straight back to play. The draft must be
	# down: the pause key is gated on `not draft.visible` so Escape on a level-up
	# card never pauses, which is correct and not what this checks.
	# Reset to plain play so this checks ESCAPE and not the previous cycle's
	# admin_return. Escape from play is the path a player actually takes.
	hud.draft.hide()
	hud.draft.choices.clear()
	hud.close_admin()
	await process_frame
	assert(hud.menu_kind != "admin", "could not return to play: kind=%s" % hud.menu_kind)
	hotkey_open(hud)
	await process_frame
	assert(hud.admin_return == "play", "console opened over play recorded '%s'" % hud.admin_return)
	press_escape(hud)
	await process_frame
	assert(hud.menu_kind != "admin", "escape did not close the console (kind=%s)" % hud.menu_kind)
	hotkey_open(hud)
	await process_frame
	assert(hud.menu_kind == "admin" and hud.menu.visible, "console did not reopen after escape")
	await reopen_cycles(hud, "escape")

	# And from the DRAFT screen, whose close branch hides the menu directly.
	var go_draft := find_button(hud.menu, "Return")
	assert(go_draft != null, "no Return button")
	go_draft.pressed.emit()
	await process_frame
	hud.draft.show()
	hud.draft.render()
	await process_frame
	hotkey_open(hud)
	await process_frame
	assert(hud.menu_kind == "admin" and hud.menu.visible, "console did not open over the draft")
	assert(panel_height(hud) <= EXPECTED_MAX, "console overflowed over the draft: %.0f" % panel_height(hud))
	for i in 3:
		var back := find_button(hud.menu, "Return")
		assert(back != null, "no Return button in cycle %d" % i)
		back.pressed.emit()
		await process_frame
		assert(hud.draft.visible, "cycle %d: Return did not restore the draft" % i)
		hotkey_open(hud)
		await process_frame
		assert(hud.menu_kind == "admin" and hud.menu.visible, "cycle %d: console did not reopen over the draft" % i)
	# Leave the draft so the run state is what a player would have.
	hud.draft.hide()
	hud.resume()
	await process_frame
	assert(hud.menu_kind != "admin", "the console was left open after the draft section")
	print("ADMIN PANEL PASS: fits on first open, every control keeps it at %.0fpx, banner never overlays, reopens after every close path" % baseline)
	quit(0)

func arsenal_check(game) -> bool:
	for data in game.arsenal.weapon_catalog:
		if game.arsenal.weapons.has(data.id):
			if game.arsenal.weapons[data.id].level != 8:
				return false
	for data in game.arsenal.passive_catalog:
		if int(game.arsenal.passive_levels.get(data.id, 0)) < data.max_level:
			return false
	return game.arsenal.trinkets.size() == game.arsenal.trinket_slots()
