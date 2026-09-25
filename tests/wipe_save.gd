extends SceneTree
# The main-menu save wipe: it must erase progress and keep preferences, write a fresh file,
# still write when the old file was unreadable/newer, and be reachable from the title menu
# only on the SECOND press. The real save file is snapshotted first and restored at the end.
var fails: Array[String] = []
var save_path: String = ProjectSettings.globalize_path("user://vespercoil.cfg")
var snapshot: PackedByteArray = PackedByteArray()
var had_save: bool = false
func chk(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
func snapshot_save() -> void:
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f != null:
		had_save = true
		snapshot = f.get_buffer(f.get_length())
		f.close()
func restore_save() -> void:
	if had_save:
		var f := FileAccess.open(save_path, FileAccess.WRITE)
		if f != null:
			f.store_buffer(snapshot)
			f.close()
	else:
		DirAccess.remove_absolute(save_path)
func find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text.begins_with(text):
		return node
	for child in node.get_children():
		var found: Button = find_button(child, text)
		if found != null:
			return found
	return null
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	snapshot_save()
	var meta = root.get_node("MetaProgression")
	# --- the wipe itself -------------------------------------------------------------
	meta.gold = 4242
	for key in meta.bonuses:
		meta.bonuses[key] = 3
	if not meta.unlocked.has("Warden"):
		meta.unlocked.append("Warden")
	meta.selected = "Warden"
	meta.difficulty = 2
	meta.mode = "daily"
	meta.daily_key = "2026-09-23"
	meta.daily_best = 99
	meta.daily_best_ascension = 4
	meta.progress["wins"] = 3.0
	meta.progress["regions_cleared"] = {"ember": 1.0}
	meta.unlocked_achievements.append("first_blood")
	meta.settings["shake"] = false
	meta.save_data()
	var seeded := ConfigFile.new()
	chk(seeded.load(save_path) == OK and int(seeded.get_value("save", "gold", -1)) == 4242, "seed: the save file did not hold the seeded progress")
	meta.wipe_save()
	chk(meta.gold == 0, "wipe: gold is %d" % meta.gold)
	for key in meta.bonuses:
		chk(int(meta.bonuses[key]) == 0, "wipe: bonus %s is %d" % [key, int(meta.bonuses[key])])
	chk(meta.unlocked.size() == meta.FRESH_UNLOCKED.size(), "wipe: %d characters unlocked, expected %d" % [meta.unlocked.size(), meta.FRESH_UNLOCKED.size()])
	for name in meta.FRESH_UNLOCKED:
		chk(meta.unlocked.has(name), "wipe: %s is no longer unlocked" % name)
	chk(not meta.unlocked.has("Warden"), "wipe: the awakened keeper survived")
	chk(meta.selected == "Ranger" and meta.difficulty == 0 and meta.region == 0, "wipe: selection is %s / %d / region %d" % [meta.selected, meta.difficulty, meta.region])
	chk(meta.mode == "expedition" and meta.daily_best == 0 and meta.daily_key == "", "wipe: daily best %d and mode %s survived" % [meta.daily_best, meta.mode])
	chk(meta.progress.is_empty() and meta.unlocked_achievements.is_empty(), "wipe: %d progress keys and %d achievements survived" % [meta.progress.size(), meta.unlocked_achievements.size()])
	chk(meta.settings["shake"] == false, "wipe: settings were reset too (they must survive)")
	var fresh := ConfigFile.new()
	chk(fresh.load(save_path) == OK, "wipe: no save file was written")
	chk(int(fresh.get_value("save", "gold", -1)) == 0, "wipe: the file still holds %d gold" % int(fresh.get_value("save", "gold", -1)))
	chk(str(fresh.get_value("save", "selected", "")) == "Ranger", "wipe: the file still selects %s" % str(fresh.get_value("save", "selected", "")))
	chk(not bool(fresh.get_value("characters", "Warden", false)), "wipe: the file still unlocks Warden")
	chk(not fresh.has_section("progress") or fresh.get_section_keys("progress").is_empty(), "wipe: the file still holds progress keys")
	chk(not fresh.has_section("achievements") or fresh.get_section_keys("achievements").is_empty(), "wipe: the file still holds achievements")
	chk(fresh.get_value("settings", "shake", true) == false, "wipe: the file lost the settings")
	# An unreadable or newer save disables writing; a wipe must still land.
	meta.gold = 777
	meta.future_version = true
	meta.wipe_save()
	var forced := ConfigFile.new()
	chk(forced.load(save_path) == OK and int(forced.get_value("save", "gold", -1)) == 0, "wipe: a newer/unreadable save was preserved instead of wiped")
	# --- the button in Settings, reached from the uncluttered main menu ---------------
	meta.launching = false
	meta.gold = 900
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 4:
		await process_frame
	var settings: Button = find_button(game.hud.menu_column, "Settings")
	chk(settings != null, "menu: no Settings button on the title screen")
	if settings != null:
		settings.pressed.emit()
	chk(game.hud.menu_kind == "settings", "menu: Settings did not open")
	var wipe: Button = find_button(game.hud.menu_column, "Clear save")
	chk(wipe != null, "menu: no Clear save button in Settings")
	if wipe != null:
		wipe.pressed.emit()
		chk(meta.gold == 900, "menu: the first press already wiped the save")
		chk(wipe.text != "Clear save", "menu: the first press did not arm the button")
		wipe.pressed.emit()
		chk(meta.gold == 0, "menu: the second press left %d gold" % meta.gold)
		chk(game.hud.menu_kind == "title" and find_button(game.hud.menu_column, "Settings") != null, "menu: the title screen did not rebuild after the wipe")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.25, true, false, true).timeout
	restore_save()
	if fails.is_empty():
		print("WIPE SAVE PASS: menu button arms then erases on the second press, gold/keepers/records/achievements cleared in memory and on disk, settings kept, newer saves still overwritable.")
		quit(0)
	else:
		print("WIPE SAVE FAIL (%d):" % fails.size())
		for f in fails:
			print("  ", f)
		quit(1)
