extends SceneTree

# Covers the first-expedition guide: who is offered it, that its seed is fixed, that each step
# fires off its own action in any order, and that finishing it retires the guide for good.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var meta = root.get_node("MetaProgression")
	# Autoload identifiers are not compile-time globals inside a --script run, so reach them
	# through the tree the way the other suites do.
	var runs = root.get_node("RunManager")
	var events = root.get_node("GameEvents")
	meta.future_version = true # Never write the player's profile from a test.
	meta.reset_progress()
	meta.tutorial_run = false

	# --- Who is offered the guide ---
	assert(meta.tutorial_pending())
	meta.progress["runs"] = 5.0
	assert(not meta.tutorial_pending()) # Veterans are never interrupted.
	meta.progress.erase("runs")
	meta.progress["wins"] = 1.0
	assert(not meta.tutorial_pending()) # Nor anyone who has already finished a ground.
	meta.progress.erase("wins")
	assert(meta.tutorial_pending())

	# --- The guided run always seeds the same ground ---
	meta.seed_override = meta.TUTORIAL_SEED
	runs.start()
	var first: int = runs.run_seed
	runs.start()
	assert(first == meta.TUTORIAL_SEED and runs.run_seed == first)
	meta.seed_override = 0

	# --- The step machine ---
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var hud = game.hud
	meta.progress.erase("tutorial_done")
	meta.tutorial_run = true
	hud.guide_active = false
	hud.guide_done = {}
	hud.refresh_guide()
	assert(hud.guide_active and hud.guide_label.visible)
	assert(hud.guide_label.text.contains("ATLAS"))
	# Steps are independent of order: each action ticks its own step off.
	hud.open_map(false)
	assert(hud.guide_label.text.contains("DRAFT"))
	events.draft_resolved.emit(0)
	assert(hud.guide_label.text.contains("CACHE"))
	events.notice.emit("SUPPLY CACHE", "test", Color.GOLD)
	assert(hud.guide_label.text.contains("BEACON"))
	events.notice.emit("BEACON RESTORED", "test", Color.GOLD)
	assert(not hud.guide_active and not hud.guide_label.visible)
	assert(meta.progress_of("tutorial_done") > 0.0 and not meta.tutorial_run)
	assert(not meta.tutorial_pending()) # It does not come back.

	# A disarmed profile gets no label even if the run is live.
	hud.guide_active = false
	hud.guide_done = {}
	meta.tutorial_run = false
	hud.refresh_guide()
	assert(not hud.guide_active and not hud.guide_label.visible)

	# --- Arming: the decision behind the title button, without reloading the scene ---
	meta.reset_progress()
	meta.seed_override = 0
	meta.tutorial_run = false
	assert(hud.arm_tutorial())
	assert(meta.seed_override == meta.TUTORIAL_SEED and meta.tutorial_run)
	var kept: int = meta.seed_override
	meta.tutorial_run = false
	assert(hud.arm_tutorial() and meta.seed_override == kept) # Re-entering keeps the ground.
	meta.progress["wins"] = 1.0
	meta.tutorial_run = true
	assert(not hud.arm_tutorial() and not meta.tutorial_run) # A won profile is never armed.
	meta.progress.erase("wins")
	meta.seed_override = 0

	# The title screen offers the guided run by name while it is pending.
	meta.reset_progress()
	meta.tutorial_run = false
	hud.title_screen()
	var begin_button: Button = null
	for child in hud.menu_column.get_children():
		if child is Button and String(child.text).contains("FIRST EXPEDITION"):
			begin_button = child
	assert(begin_button != null)

	print("TUTORIAL PASS: gating, fixed seed, four order-independent steps, completion and title entry")
	meta.reset_progress()
	meta.tutorial_run = false
	meta.seed_override = 0
	game.queue_free()
	await process_frame
	quit()
