extends Node
const VERSION: int = 3
const SAVE_PATH: String = "user://vespercoil.cfg"
const DIFFICULTIES: Array[Dictionary] = [
	{"name": "WAYFARER", "health": 1.0, "incoming": 1.0, "spawn": 1.0, "gold": 1.0, "description": "The original expedition"},
	{"name": "VETERAN", "health": 1.45, "incoming": 1.25, "spawn": 0.8, "gold": 1.25, "description": "+45% enemy HP / +25% damage / faster waves / +25% gold"},
	{"name": "NIGHTMARE", "health": 2.0, "incoming": 1.5, "spawn": 0.65, "gold": 1.5, "description": "2x enemy HP / +50% damage / dense waves / +50% gold"},
]
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
# Every keeper that has to be earned. A fresh save awakens only FRESH_UNLOCKED.
# Clearing a ground is the headline route and each region file names its own keeper
# in reward_character; MILESTONE_UNLOCKS is the single-run feat that also works.
const NEW_UNLOCKS: Array[String] = [
	"Artificer", "Pathfinder", "Cinderkeeper", "Frostweaver",
	"Warden", "Arcanist", "Salvager", "Archivist",
	"Hexblade", "Eclipse", "Ravager", "Glazier",
	"Fenwalker", "Starwright", "Veilbinder", "Ashcaller",
	"Stormwright", "Brinelord", "Polaris",
]
# The alternate route: one hard feat inside a single run awakens a keeper, so a
# player still sealed out of a ground can widen the roster. `stat` names the run
# counter, `at` is the threshold; "difficulty" counts only on a win.
const MILESTONE_UNLOCKS: Array[Dictionary] = [
	{"character": "Artificer", "stat": "kills", "at": 100.0, "hint": "defeat 100 enemies in one run"},
	{"character": "Pathfinder", "stat": "kills", "at": 250.0, "hint": "defeat 250 enemies in one run"},
	{"character": "Cinderkeeper", "stat": "kills", "at": 400.0, "hint": "defeat 400 enemies in one run"},
	{"character": "Warden", "stat": "kills", "at": 500.0, "hint": "defeat 500 enemies in one run"},
	{"character": "Arcanist", "stat": "seconds", "at": 600.0, "hint": "survive ten minutes in one run"},
	{"character": "Frostweaver", "stat": "difficulty", "at": 1.0, "hint": "win a run on Veteran or Nightmare"},
	{"character": "Hexblade", "stat": "kills", "at": 750.0, "hint": "defeat 750 enemies in one run"},
	{"character": "Eclipse", "stat": "difficulty", "at": 2.0, "hint": "win a run on Nightmare"},
	{"character": "Ravager", "stat": "kills", "at": 1500.0, "hint": "defeat 1,500 enemies in one run"},
	{"character": "Salvager", "stat": "caches", "at": 3.0, "hint": "open 3 caches in one run"},
	{"character": "Archivist", "stat": "rooms", "at": 1.0, "hint": "discover a hidden room"},
	{"character": "Glazier", "stat": "caches", "at": 6.0, "hint": "open 6 caches in one run"},
	{"character": "Fenwalker", "stat": "caches", "at": 5.0, "hint": "open 5 caches in one run"},
	{"character": "Starwright", "stat": "seconds", "at": 300.0, "hint": "survive five minutes in one run"},
	{"character": "Veilbinder", "stat": "kills", "at": 900.0, "hint": "defeat 900 enemies in one run"},
	{"character": "Ashcaller", "stat": "rooms", "at": 2.0, "hint": "discover two hidden rooms"},
	{"character": "Stormwright", "stat": "kills", "at": 1200.0, "hint": "defeat 1,200 enemies in one run"},
	{"character": "Brinelord", "stat": "seconds", "at": 900.0, "hint": "survive fifteen minutes in one run"},
	{"character": "Polaris", "stat": "kills", "at": 2000.0, "hint": "defeat 2,000 enemies in one run"},
]
const BOSS_UPGRADE_REQUIRES: Dictionary = {
	"boss_veilwood": "veilwood",
	"boss_cinder_reach": "cinder_reach",
	"boss_storm_citadel": "storm_citadel",
	"boss_tidal_maw": "tidal_maw",
	"boss_black_aurora": "black_aurora",
	"boss_veilwood_edge": "veilwood",
	"boss_storm_ward": "storm_citadel",
	"boss_tidal_greed": "tidal_maw",
	"boss_veilwood_bloom": "veilwood",
	"boss_cinder_crown": "cinder_reach",
	"boss_storm_conduit": "storm_citadel",
	"boss_tidal_shell": "tidal_maw",
	"boss_aurora_prism": "black_aurora",
	"boss_cinder_ash": "cinder_reach",
	&"boss_veilwood_heartwood": "veilwood",
	&"boss_veilwood_deeproots": "veilwood",
	&"boss_veilwood_groveguard": "veilwood",
	&"boss_veilwood_bounty": "veilwood",
	&"boss_cinder_kindling": "cinder_reach",
	&"boss_cinder_hearthguard": "cinder_reach",
	&"boss_cinder_forge_edge": "cinder_reach",
	&"boss_cinder_ember_crown": "cinder_reach",
	&"boss_storm_static_charge": "storm_citadel",
	&"boss_storm_skyshroud": "storm_citadel",
	&"boss_storm_thunder_focus": "storm_citadel",
	&"boss_storm_overcharge": "storm_citadel",
	&"boss_tidal_deepcurrent": "tidal_maw",
	&"boss_tidal_tidegold": "tidal_maw",
	&"boss_tidal_undertow": "tidal_maw",
	&"boss_tidal_abyss_plate": "tidal_maw",
	&"boss_black_eclipse": "black_aurora",
	&"boss_black_voidlance": "black_aurora",
	&"boss_black_prism_recoil": "black_aurora",
	&"boss_black_meridian": "black_aurora",
}
const BOSS_UPGRADE_NAMES: Dictionary = {
	"veilwood": "THE VERDANT WARDEN",
	"cinder_reach": "THE CINDER MONARCH",
	"storm_citadel": "THE STORM ARCHON",
	"tidal_maw": "THE ABYSSAL MONARCH",
	"black_aurora": "THE BLACK AURORA",
}
const NEW_STAT_BONUSES: Dictionary = {
	"tempered_edge": [[&"mult_physical", 0.0, 0.06], [&"crit_chance", 0.02, 0.0]],
	"quickdraw": [[&"cdr", 0.03, 0.0], [&"area", 0.0, 0.05]],
	"wide_arc": [[&"area", 0.0, 0.08], [&"mult_physical", 0.0, 0.04]],
	"critical_mass": [[&"crit_damage", 0.04, 0.0], [&"crit_chance", 0.01, 0.0]],
	"ember_fang": [[&"mult_fire", 0.0, 0.07], [&"mult_physical", 0.0, 0.03]],
	"glacial_edge": [[&"mult_ice", 0.0, 0.07], [&"area", 0.0, 0.04]],
	"storm_lance": [[&"mult_lightning", 0.0, 0.07], [&"crit_damage", 0.03, 0.0]],
	"void_cut": [[&"mult_true", 0.0, 0.04], [&"crit_chance", 0.03, 0.0]],
	"siege_round": [[&"damage", 0.0, 0.06], [&"area", 0.0, 0.06]],
	"frost_ward": [[&"resist_ice", 0.06, 0.0]],
	"lightning_ward": [[&"resist_lightning", 0.06, 0.0]],
	"iron_heart": [[&"max_health", 6.0, 0.0], [&"armour", 0.5, 0.0]],
	"moving_guard": [[&"speed", 0.0, 0.03], [&"armour", 0.5, 0.0]],
	"ember_skin": [[&"resist_fire", 0.05, 0.0], [&"max_health", 3.0, 0.0]],
	"oathshield": [[&"resist_physical", 0.05, 0.0], [&"armour", 0.5, 0.0]],
	"refuge": [[&"resist_fire", 0.04, 0.0], [&"resist_ice", 0.04, 0.0], [&"resist_lightning", 0.04, 0.0]],
	"trailblazer": [[&"speed", 0.0, 0.04], [&"pickup", 0.0, 0.04]],
	"astral_lens": [[&"xp", 0.0, 0.05], [&"pickup", 0.0, 0.05]],
	"fortune_finder": [[&"gold", 0.0, 0.06], [&"xp", 0.0, 0.03]],
	"deep_pockets": [[&"gold", 0.0, 0.03]],
	"swift_harvest": [[&"pickup", 0.0, 0.07], [&"speed", 0.0, 0.02]],
	"guiding_star": [[&"xp", 0.0, 0.06], [&"cdr", 0.02, 0.0]],
	"vanguard_steps": [[&"speed", 0.0, 0.04], [&"xp", 0.0, 0.04]],
	"blood_oath": [[&"damage", 0.0, 0.12], [&"max_health", -8.0, 0.0], [&"curse", 1.0, 0.0]],
	"fever_pitch": [[&"cdr", 0.05, 0.0], [&"armour", -0.5, 0.0], [&"curse", 1.0, 0.0]],
	"storm_pact": [[&"mult_lightning", 0.0, 0.15], [&"max_health", -5.0, 0.0], [&"curse", 1.0, 0.0]],
	"frozen_bargain": [[&"mult_ice", 0.0, 0.12], [&"speed", 0.0, -0.03], [&"curse", 1.0, 0.0]],
	"gilded_danger": [[&"gold", 0.0, 0.15], [&"speed", 0.0, -0.03], [&"curse", 1.0, 0.0]],
	"abyss_hunger": [[&"xp", 0.0, 0.10], [&"max_health", -6.0, 0.0], [&"curse", 1.0, 0.0]],
	"boss_veilwood_bloom": [[&"max_health", 8.0, 0.0], [&"xp", 0.0, 0.05]],
	"boss_cinder_crown": [[&"mult_fire", 0.0, 0.12], [&"resist_fire", 0.05, 0.0]],
	"boss_storm_conduit": [[&"mult_lightning", 0.0, 0.10], [&"cdr", 0.02, 0.0]],
	"boss_tidal_shell": [[&"resist_physical", 0.06, 0.0], [&"pickup", 0.0, 0.06]],
	"boss_aurora_prism": [[&"crit_chance", 0.03, 0.0], [&"mult_true", 0.0, 0.06]],
	"boss_cinder_ash": [[&"mult_physical", 0.0, 0.06], [&"mult_fire", 0.0, 0.06]],
	"keening_edge": [[&"damage", 0, 0.05], [&"crit_chance", 0.01, 0]],
	"forked_volley": [[&"projectiles", 1, 0], [&"area", 0, 0.04]],
	"ember_oath": [[&"mult_fire", 0, 0.07]],
	"glacial_oath": [[&"mult_ice", 0, 0.07]],
	"storm_oath": [[&"mult_lightning", 0, 0.07]],
	"honed_edge": [[&"damage", 0, 0.06], [&"mult_physical", 0, 0.03]],
	"execution_rite": [[&"damage", 0, 0.04], [&"crit_chance", 0.02, 0]],
	"finishing_arc": [[&"crit_damage", 0.05, 0], [&"damage", 0, 0.04]],
	"deep_cut": [[&"mult_physical", 0, 0.05], [&"damage", 0, 0.05]],
	"cinderbrand": [[&"mult_fire", 0, 0.07], [&"damage", 0, 0.03]],
	"flare_step": [[&"mult_fire", 0, 0.05], [&"area", 0, 0.04], [&"speed", 0, 0.03]],
	"frostbrand": [[&"mult_ice", 0, 0.07], [&"damage", 0, 0.03]],
	"shattercold": [[&"mult_ice", 0, 0.05], [&"crit_chance", 0.01, 0]],
	"stormbrand": [[&"mult_lightning", 0, 0.07], [&"damage", 0, 0.03]],
	"voltaic_rhythm": [[&"mult_lightning", 0, 0.05], [&"cdr", 0.03, 0]],
	"double_tap": [[&"damage", 0, 0.04], [&"cdr", 0.03, 0]],
	"swift_flurry": [[&"damage", 0, 0.04], [&"cdr", 0.03, 0], [&"area", 0, 0.05]],
	"rifle_pace": [[&"cdr", 0.03, 0], [&"mult_physical", 0, 0.04]],
	"hunt_step": [[&"damage", 0, 0.05], [&"area", 0, 0.05], [&"speed", 0, 0.03]],
	"execution_surge": [[&"crit_chance", 0.02, 0], [&"crit_damage", 0.04, 0], [&"damage", 0, 0.04]],
	"stone_blood": [[&"max_health", 6, 0], [&"resist_physical", 0.04, 0]],
	"elemental_aegis": [[&"resist_fire", 0.04, 0], [&"resist_ice", 0.04, 0], [&"resist_lightning", 0.04, 0]],
	"windstep": [[&"speed", 0, 0.04], [&"pickup", 0, 0.05]],
	"second_pulse": [[&"cdr", 0.03, 0], [&"max_health", 4, 0]],
	"sparkshrine": [[&"pickup", 0, 0.07], [&"xp", 0, 0.05]],
	"fortified_frame": [[&"max_health", 4, 0], [&"armour", 0.5, 0]],
	"tower_guard": [[&"max_health", 6, 0], [&"armour", 0.5, 0], [&"resist_physical", 0.03, 0]],
	"molten_aegis": [[&"resist_fire", 0.06, 0], [&"max_health", 3, 0]],
	"glacial_aegis": [[&"resist_ice", 0.06, 0], [&"max_health", 3, 0]],
	"voltaic_aegis": [[&"resist_lightning", 0.06, 0], [&"max_health", 3, 0]],
	"all_weather": [[&"resist_fire", 0.05, 0], [&"resist_ice", 0.05, 0], [&"resist_lightning", 0.05, 0]],
	"fleet_guard": [[&"speed", 0, 0.04], [&"armour", 0.5, 0]],
	"stormfoot": [[&"speed", 0, 0.04], [&"cdr", 0.03, 0]],
	"pulse_battery": [[&"cdr", 0.03, 0], [&"pickup", 0, 0.05]],
	"siphon_guard": [[&"pickup", 0, 0.07], [&"max_health", 3, 0]],
	"frontier_survival": [[&"speed", 0, 0.03], [&"pickup", 0, 0.04], [&"xp", 0, 0.06]],
	"cinder_kin": [[&"resist_fire", 0.05, 0], [&"pickup", 0, 0.05]],
	"briar_kin": [[&"resist_ice", 0.05, 0], [&"max_health", 3, 0]],
	"storm_kin": [[&"resist_lightning", 0.05, 0], [&"cdr", 0.03, 0]],
	"oath_of_continuity": [[&"max_health", 8, 0], [&"armour", 0.5, 0]],
	"wayfarer_stride": [[&"speed", 0, 0.04], [&"pickup", 0, 0.03]],
	"salvager_sense": [[&"pickup", 0, 0.08], [&"gold", 0, 0.04]],
	"trail_clock": [[&"cdr", 0.03, 0], [&"max_health", 2, 0]],
	"open_quiver": [[&"projectiles", 1, 0], [&"cdr", 0.02, 0]],
	"far_scout": [[&"xp", 0, 0.06], [&"pickup", 0, 0.03]],
	"long_road": [[&"speed", 0, 0.04], [&"xp", 0, 0.04], [&"max_health", 2, 0]],
	"swift_cache": [[&"pickup", 0, 0.07], [&"gold", 0, 0.05]],
	"measured_march": [[&"cdr", 0.04, 0], [&"area", 0, 0.06], [&"max_health", 2, 0]],
	"split_the_trail": [[&"projectiles", 1, 0], [&"pickup", 0, 0.05]],
	"star_chart": [[&"xp", 0, 0.06], [&"cdr", 0.02, 0]],
	"dust_road": [[&"speed", 0, 0.04], [&"pickup", 0, 0.04]],
	"salvage_ledger": [[&"gold", 0, 0.07], [&"xp", 0, 0.04]],
	"field_reserve": [[&"xp", 0, 0.06], [&"max_health", 2, 0]],
	"far_reach": [[&"pickup", 0, 0.08], [&"area", 0, 0.04]],
	"pacer_ritual": [[&"speed", 0, 0.05], [&"cdr", 0.03, 0]],
	"salvage_sprint": [[&"gold", 0, 0.05], [&"pickup", 0, 0.05]],
	"clockwork_trek": [[&"cdr", 0.04, 0], [&"area", 0, 0.05]],
	"horizon_sight": [[&"xp", 0, 0.05], [&"pickup", 0, 0.05]],
	"wayfarer_cache": [[&"speed", 0, 0.04], [&"pickup", 0, 0.06]],
	"prismatic_horizon": [[&"pickup", 0, 0.06], [&"xp", 0, 0.04]],
	"dangerous_ambition": [[&"gold", 0, 0.12], [&"max_health", -3, 0], [&"curse", 1, 0]],
	"barbed_pact": [[&"mult_physical", 0, 0.12], [&"armour", -0.5, 0], [&"curse", 1, 0]],
	"ember_gamble": [[&"mult_fire", 0, 0.14], [&"max_health", -4, 0], [&"curse", 1, 0]],
	"frost_gamble": [[&"mult_ice", 0, 0.12], [&"speed", 0, -0.03], [&"curse", 1, 0]],
	"storm_gamble": [[&"mult_lightning", 0, 0.15], [&"max_health", -5, 0], [&"curse", 1, 0]],
	"crimson_ambition": [[&"damage", 0, 0.1], [&"max_health", -3, 0], [&"curse", 1, 0]],
	"gilded_edge": [[&"gold", 0, 0.12], [&"max_health", -2, 0], [&"curse", 1, 0]],
	"brutal_reflex": [[&"mult_physical", 0, 0.1], [&"armour", -0.5, 0], [&"curse", 1, 0]],
	"ember_surge": [[&"mult_fire", 0, 0.12], [&"max_health", -3, 0], [&"curse", 1, 0]],
	"frost_surge": [[&"mult_ice", 0, 0.12], [&"speed", 0, -0.03], [&"curse", 1, 0]],
	"storm_surge": [[&"mult_lightning", 0, 0.12], [&"max_health", -3, 0], [&"curse", 1, 0]],
	"redline_reprise": [[&"speed", 0, 0.1], [&"armour", -0.5, 0], [&"curse", 1, 0]],
	"cursed_purse": [[&"gold", 0, 0.15], [&"max_health", -4, 0], [&"curse", 1, 0]],
	"ember_reverie": [[&"mult_fire", 0, 0.12], [&"max_health", -4, 0], [&"curse", 1, 0]],
	"glacial_reverie": [[&"mult_ice", 0, 0.12], [&"speed", 0, -0.03], [&"curse", 1, 0]],
	"storm_reverie": [[&"mult_lightning", 0, 0.12], [&"max_health", -4, 0], [&"curse", 1, 0]],
	"crimson_reverie": [[&"damage", 0, 0.1], [&"max_health", -4, 0], [&"curse", 1, 0]],
	"mercury_malice": [[&"cdr", 0.04, 0], [&"armour", -0.5, 0], [&"curse", 1, 0]],
	"deep_greed": [[&"gold", 0, 0.15], [&"max_health", -5, 0], [&"curse", 1, 0]],
	"cataclysmic_pact": [[&"damage", 0, 0.1], [&"max_health", -6, 0], [&"curse", 1, 0]],
	"boss_veilwood_heartwood": [[&"max_health", 6, 0], [&"resist_physical", 0.05, 0]],
	"boss_veilwood_deeproots": [[&"speed", 0, 0.03], [&"pickup", 0, 0.06]],
	"boss_veilwood_groveguard": [[&"max_health", 6, 0], [&"resist_ice", 0.05, 0]],
	"boss_veilwood_bounty": [[&"xp", 0, 0.05], [&"gold", 0, 0.06]],
	"boss_cinder_kindling": [[&"mult_fire", 0, 0.07], [&"cdr", 0.03, 0]],
	"boss_cinder_hearthguard": [[&"max_health", 6, 0], [&"armour", 0.5, 0]],
	"boss_cinder_forge_edge": [[&"damage", 0, 0.06], [&"mult_physical", 0, 0.07]],
	"boss_cinder_ember_crown": [[&"mult_fire", 0, 0.07], [&"resist_fire", 0.05, 0]],
	"boss_storm_static_charge": [[&"cdr", 0.03, 0], [&"mult_lightning", 0, 0.07]],
	"boss_storm_skyshroud": [[&"max_health", 6, 0], [&"resist_lightning", 0.05, 0]],
	"boss_storm_thunder_focus": [[&"crit_chance", 0.02, 0], [&"crit_damage", 0.04, 0]],
	"boss_storm_overcharge": [[&"damage", 0, 0.06], [&"mult_lightning", 0, 0.07]],
	"boss_tidal_deepcurrent": [[&"speed", 0, 0.03], [&"pickup", 0, 0.06]],
	"boss_tidal_tidegold": [[&"gold", 0, 0.06], [&"xp", 0, 0.05]],
	"boss_tidal_undertow": [[&"area", 0, 0.06], [&"damage", 0, 0.06]],
	"boss_tidal_abyss_plate": [[&"max_health", 6, 0], [&"resist_physical", 0.05, 0]],
	"boss_black_eclipse": [[&"crit_chance", 0.02, 0], [&"crit_damage", 0.04, 0]],
	"boss_black_voidlance": [[&"mult_physical", 0, 0.07], [&"damage", 0, 0.06]],
	"boss_black_prism_recoil": [[&"area", 0, 0.06], [&"crit_damage", 0.04, 0]],
	"boss_black_meridian": [[&"speed", 0, 0.03], [&"pickup", 0, 0.06]],
}

const MAX: Dictionary = {
	"might": 20,
	"precision": 5,
	"execution": 5,
	"volley": 1,
	"area": 3,
	"fire": 3,
	"ice": 3,
	"lightning": 3,
	"knockback": 3,
	"vitality": 20,
	"aegis": 5,
	"revive": 2,
	"physical_ward": 3,
	"fire_ward": 3,
	"boots": 20,
	"haste": 5,
	"wisdom": 5,
	"reroll": 5,
	"reserve": 5,
	"pickup": 3,
	"gold": 3,
	"banish": 2,
	"trinket_slot": 1,
	"curse": 5,
	"boss_veilwood": 3,
	"boss_cinder_reach": 3,
	"boss_storm_citadel": 3,
	"boss_tidal_maw": 3,
	"boss_black_aurora": 3,
	"physical_edge": 3,
	"piercing": 2,
	"ballistics": 3,
	"catalyst": 2,
	"armor_break": 3,
	"evasion": 3,
	"regeneration": 3,
	"last_stand": 3,
	"cursed_plate": 2,
	"beacon_focus": 3,
	"contract_scribe": 3,
	"cache_salvage": 3,
	"early_evolution": 3,
	"event_surveyor": 3,
	"glass_cannon": 3,
	"gilded_famine": 3,
	"redline": 3,
	"boss_veilwood_edge": 3,
	"boss_storm_ward": 3,
	"boss_tidal_greed": 3,
	"tempered_edge": 3,
	"quickdraw": 3,
	"wide_arc": 3,
	"critical_mass": 3,
	"ember_fang": 3,
	"glacial_edge": 3,
	"storm_lance": 3,
	"void_cut": 3,
	"siege_round": 3,
	"frost_ward": 3,
	"lightning_ward": 3,
	"iron_heart": 3,
	"moving_guard": 3,
	"ember_skin": 3,
	"oathshield": 3,
	"refuge": 3,
	"trailblazer": 3,
	"astral_lens": 3,
	"fortune_finder": 3,
	"deep_pockets": 3,
	"swift_harvest": 3,
	"guiding_star": 3,
	"vanguard_steps": 3,
	"blood_oath": 3,
	"fever_pitch": 3,
	"storm_pact": 3,
	"frozen_bargain": 3,
	"gilded_danger": 3,
	"abyss_hunger": 3,
	"boss_veilwood_bloom": 3,
	"boss_cinder_crown": 3,
	"boss_storm_conduit": 3,
	"boss_tidal_shell": 3,
	"boss_aurora_prism": 3,
	"boss_cinder_ash": 3,
	&"keening_edge": 4,
	&"forked_volley": 1,
	&"ember_oath": 4,
	&"glacial_oath": 4,
	&"storm_oath": 4,
	&"honed_edge": 3,
	&"execution_rite": 4,
	&"finishing_arc": 3,
	&"deep_cut": 3,
	&"cinderbrand": 3,
	&"flare_step": 3,
	&"frostbrand": 3,
	&"shattercold": 3,
	&"stormbrand": 3,
	&"voltaic_rhythm": 3,
	&"double_tap": 3,
	&"swift_flurry": 3,
	&"rifle_pace": 3,
	&"hunt_step": 3,
	&"execution_surge": 3,
	&"stone_blood": 4,
	&"elemental_aegis": 3,
	&"windstep": 4,
	&"second_pulse": 4,
	&"sparkshrine": 3,
	&"fortified_frame": 3,
	&"tower_guard": 3,
	&"molten_aegis": 3,
	&"glacial_aegis": 3,
	&"voltaic_aegis": 3,
	&"all_weather": 2,
	&"fleet_guard": 3,
	&"stormfoot": 3,
	&"pulse_battery": 3,
	&"siphon_guard": 3,
	&"frontier_survival": 3,
	&"cinder_kin": 3,
	&"briar_kin": 3,
	&"storm_kin": 3,
	&"oath_of_continuity": 3,
	&"wayfarer_stride": 4,
	&"salvager_sense": 3,
	&"trail_clock": 3,
	&"open_quiver": 2,
	&"far_scout": 3,
	&"long_road": 3,
	&"swift_cache": 3,
	&"measured_march": 3,
	&"split_the_trail": 1,
	&"star_chart": 3,
	&"dust_road": 3,
	&"salvage_ledger": 3,
	&"field_reserve": 3,
	&"far_reach": 3,
	&"pacer_ritual": 3,
	&"salvage_sprint": 3,
	&"clockwork_trek": 2,
	&"horizon_sight": 3,
	&"wayfarer_cache": 3,
	&"prismatic_horizon": 3,
	&"dangerous_ambition": 3,
	&"barbed_pact": 3,
	&"ember_gamble": 3,
	&"frost_gamble": 3,
	&"storm_gamble": 3,
	&"crimson_ambition": 3,
	&"gilded_edge": 3,
	&"brutal_reflex": 3,
	&"ember_surge": 3,
	&"frost_surge": 3,
	&"storm_surge": 3,
	&"redline_reprise": 2,
	&"cursed_purse": 2,
	&"ember_reverie": 2,
	&"glacial_reverie": 2,
	&"storm_reverie": 2,
	&"crimson_reverie": 2,
	&"mercury_malice": 2,
	&"deep_greed": 2,
	&"cataclysmic_pact": 2,
	&"boss_veilwood_heartwood": 3,
	&"boss_veilwood_deeproots": 3,
	&"boss_veilwood_groveguard": 3,
	&"boss_veilwood_bounty": 4,
	&"boss_cinder_kindling": 3,
	&"boss_cinder_hearthguard": 3,
	&"boss_cinder_forge_edge": 2,
	&"boss_cinder_ember_crown": 4,
	&"boss_storm_static_charge": 3,
	&"boss_storm_skyshroud": 3,
	&"boss_storm_thunder_focus": 2,
	&"boss_storm_overcharge": 4,
	&"boss_tidal_deepcurrent": 3,
	&"boss_tidal_tidegold": 3,
	&"boss_tidal_undertow": 3,
	&"boss_tidal_abyss_plate": 4,
	&"boss_black_eclipse": 3,
	&"boss_black_voidlance": 3,
	&"boss_black_prism_recoil": 3,
	&"boss_black_meridian": 4,
}
const BONUS_INFO: Dictionary = {
	"might": "+3% damage",
	"precision": "+1.5% critical chance",
	"execution": "+8% critical damage",
	"volley": "+1 projectile",
	"area": "+10% weapon area",
	"fire": "+10% fire damage",
	"ice": "+10% ice damage",
	"lightning": "+10% lightning damage",
	"knockback": "+15% weapon knockback",
	"vitality": "+5 max HP",
	"aegis": "+1 armour",
	"revive": "+1 revival per run",
	"physical_ward": "+8% physical resistance",
	"fire_ward": "+8% fire resistance",
	"boots": "+2% speed",
	"haste": "+3% cooldown recovery",
	"wisdom": "+8% experience",
	"reroll": "+1 draft reroll",
	"reserve": "+40 starting gold",
	"pickup": "+20% pickup radius",
	"gold": "+10% gold",
	"banish": "+1 starting banish charge",
	"trinket_slot": "+1 trinket slot",
	"curse": "+1 curse: richer rewards, deadlier horde",
	"boss_veilwood": "+8% experience",
	"boss_cinder_reach": "+10% fire damage",
	"boss_storm_citadel": "+3% cooldown recovery",
	"boss_tidal_maw": "+15% pickup radius",
	"boss_black_aurora": "+8% critical damage",
	"physical_edge": "+10% physical damage",
	"piercing": "+1 weapon pierce",
	"ballistics": "+8% projectile speed",
	"catalyst": "+10% reaction damage",
	"armor_break": "+10% physical damage",
	"evasion": "+0.05s post-hit invulnerability",
	"regeneration": "+0.5 HP/s after 3s without damage",
	"last_stand": "-5% incoming damage below 50% health",
	"cursed_plate": "+0.5 armour per permanent Curse rank",
	"beacon_focus": "+8% experience",
	"contract_scribe": "+10% gold",
	"cache_salvage": "+20% pickup radius",
	"early_evolution": "+3% cooldown recovery",
	"event_surveyor": "+8% experience",
	"glass_cannon": "+10% damage and +1 curse",
	"gilded_famine": "+10% gold and +1 curse",
	"redline": "+8% speed and +1 curse",
	"boss_veilwood_edge": "+10% physical damage",
	"boss_storm_ward": "+3% cooldown recovery",
	"boss_tidal_greed": "+20% pickup radius",
	"tempered_edge": "+6% physical damage and +2% critical chance",
	"quickdraw": "+3% cooldown recovery and +5% projectile area",
	"wide_arc": "+8% area and +4% physical damage",
	"critical_mass": "+4% critical damage and +1% critical chance",
	"ember_fang": "+7% fire damage and +3% physical damage",
	"glacial_edge": "+7% ice damage and +4% weapon area",
	"storm_lance": "+7% lightning damage and +3% critical damage",
	"void_cut": "+4% true damage and +3% critical chance",
	"siege_round": "+6% damage and +6% area",
	"frost_ward": "+6% ice resistance",
	"lightning_ward": "+6% lightning resistance",
	"iron_heart": "+6 max HP and +0.5 armour",
	"moving_guard": "+3% speed and +0.5 armour",
	"ember_skin": "+5% fire resistance and +3 max HP",
	"oathshield": "+5% physical resistance and +0.5 armour",
	"refuge": "+4% resistance to fire, ice, and lightning",
	"trailblazer": "+4% speed and +4% pickup radius",
	"astral_lens": "+5% experience and +5% pickup radius",
	"fortune_finder": "+6% gold and +3% experience",
	"deep_pockets": "+25 starting gold and +3% gold",
	"swift_harvest": "+7% pickup radius and +2% speed",
	"guiding_star": "+6% experience and +2% cooldown recovery",
	"vanguard_steps": "+4% speed and +4% experience",
	"blood_oath": "+12% damage, -8 max HP, and +1 curse",
	"fever_pitch": "+5% cooldown recovery, -0.5 armour, and +1 curse",
	"storm_pact": "+15% lightning damage, -5 max HP, and +1 curse",
	"frozen_bargain": "+12% ice damage, -3% speed, and +1 curse",
	"gilded_danger": "+15% gold, -3% speed, and +1 curse",
	"abyss_hunger": "+10% experience, -6 max HP, and +1 curse",
	"boss_veilwood_bloom": "+8 max HP and +5% experience",
	"boss_cinder_crown": "+12% fire damage and +5% fire resistance",
	"boss_storm_conduit": "+10% lightning damage and +2% cooldown recovery",
	"boss_tidal_shell": "+6% physical resistance and +6% pickup radius",
	"boss_aurora_prism": "+3% critical chance and +6% true damage",
	"boss_cinder_ash": "+6% physical damage and +6% fire damage",
	&"keening_edge": "+5% damage, +1% critical chance",
	&"forked_volley": "+1 projectile, +4% weapon area",
	&"ember_oath": "+7% fire damage",
	&"glacial_oath": "+7% ice damage",
	&"storm_oath": "+7% lightning damage",
	&"honed_edge": "+6% damage, +3% physical damage",
	&"execution_rite": "+4% damage, +2% critical chance",
	&"finishing_arc": "+5% critical damage, +4% damage",
	&"deep_cut": "+5% physical damage, +5% damage",
	&"cinderbrand": "+7% fire damage, +3% damage",
	&"flare_step": "+5% fire damage, +4% weapon area, +3% speed",
	&"frostbrand": "+7% ice damage, +3% damage",
	&"shattercold": "+5% ice damage, +1% critical chance",
	&"stormbrand": "+7% lightning damage, +3% damage",
	&"voltaic_rhythm": "+5% lightning damage, +0.03 cooldown recovery",
	&"double_tap": "+4% damage, +0.03 cooldown recovery",
	&"swift_flurry": "+4% damage, +0.03 cooldown recovery, +5% weapon area",
	&"rifle_pace": "+0.03 cooldown recovery, +4% physical damage",
	&"hunt_step": "+5% damage, +5% weapon area, +3% speed",
	&"execution_surge": "+2% critical chance, +4% critical damage, +4% damage",
	&"stone_blood": "+6 max health, +4% physical resistance",
	&"elemental_aegis": "+4% fire resistance, +4% ice resistance, +4% lightning resistance",
	&"windstep": "+4% speed, +5% pickup radius",
	&"second_pulse": "+0.03 cooldown recovery, +4 max health",
	&"sparkshrine": "+7% pickup radius, +5% experience",
	&"fortified_frame": "+4 max health, +0.5 armour",
	&"tower_guard": "+6 max health, +0.5 armour, +3% physical resistance",
	&"molten_aegis": "+6% fire resistance, +3 max health",
	&"glacial_aegis": "+6% ice resistance, +3 max health",
	&"voltaic_aegis": "+6% lightning resistance, +3 max health",
	&"all_weather": "+5% fire resistance, +5% ice resistance, +5% lightning resistance",
	&"fleet_guard": "+4% speed, +0.5 armour",
	&"stormfoot": "+4% speed, +0.03 cooldown recovery",
	&"pulse_battery": "+0.03 cooldown recovery, +5% pickup radius",
	&"siphon_guard": "+7% pickup radius, +3 max health",
	&"frontier_survival": "+3% speed, +4% pickup radius, +6% experience",
	&"cinder_kin": "+5% fire resistance, +5% pickup radius",
	&"briar_kin": "+5% ice resistance, +3 max health",
	&"storm_kin": "+5% lightning resistance, +0.03 cooldown recovery",
	&"oath_of_continuity": "+8 max health, +0.5 armour",
	&"wayfarer_stride": "+4% speed, +3% pickup radius",
	&"salvager_sense": "+8% pickup radius, +4% gold",
	&"trail_clock": "+0.03 cooldown recovery, +2 max health",
	&"open_quiver": "+1 projectile, +0.02 cooldown recovery",
	&"far_scout": "+6% experience, +3% pickup radius",
	&"long_road": "+4% speed, +4% experience, +2 max health",
	&"swift_cache": "+7% pickup radius, +5% gold",
	&"measured_march": "+0.04 cooldown recovery, +6% weapon area, +2 max health",
	&"split_the_trail": "+1 projectile, +5% pickup radius",
	&"star_chart": "+6% experience, +0.02 cooldown recovery",
	&"dust_road": "+4% speed, +4% pickup radius",
	&"salvage_ledger": "+7% gold, +4% experience",
	&"field_reserve": "+6% experience, +2 max health",
	&"far_reach": "+8% pickup radius, +4% weapon area",
	&"pacer_ritual": "+5% speed, +0.03 cooldown recovery",
	&"salvage_sprint": "+5% gold, +5% pickup radius",
	&"clockwork_trek": "+0.04 cooldown recovery, +5% weapon area",
	&"horizon_sight": "+5% experience, +5% pickup radius",
	&"wayfarer_cache": "+4% speed, +6% pickup radius",
	&"prismatic_horizon": "+6% pickup radius, +4% experience",
	&"dangerous_ambition": "+12% gold, −3 max health, +1 Curse",
	&"barbed_pact": "+12% physical damage, −0.5 armour, +1 Curse",
	&"ember_gamble": "+14% fire damage, −4 max health, +1 Curse",
	&"frost_gamble": "+12% ice damage, −3% speed, +1 Curse",
	&"storm_gamble": "+15% lightning damage, −5 max health, +1 Curse",
	&"crimson_ambition": "+10% damage, −3 max health, +1 Curse",
	&"gilded_edge": "+12% gold, −2 max health, +1 Curse",
	&"brutal_reflex": "+10% physical damage, −0.5 armour, +1 Curse",
	&"ember_surge": "+12% fire damage, −3 max health, +1 Curse",
	&"frost_surge": "+12% ice damage, −3% speed, +1 Curse",
	&"storm_surge": "+12% lightning damage, −3 max health, +1 Curse",
	&"redline_reprise": "+10% speed, −0.5 armour, +1 Curse",
	&"cursed_purse": "+15% gold, −4 max health, +1 Curse",
	&"ember_reverie": "+12% fire damage, −4 max health, +1 Curse",
	&"glacial_reverie": "+12% ice damage, −3% speed, +1 Curse",
	&"storm_reverie": "+12% lightning damage, −4 max health, +1 Curse",
	&"crimson_reverie": "+10% damage, −4 max health, +1 Curse",
	&"mercury_malice": "+0.04 cooldown recovery, −0.5 armour, +1 Curse",
	&"deep_greed": "+15% gold, −5 max health, +1 Curse",
	&"cataclysmic_pact": "+10% damage, −6 max health, +1 Curse",
	&"boss_veilwood_heartwood": "+6 max health, +5% physical resistance",
	&"boss_veilwood_deeproots": "+3% speed, +6% pickup radius",
	&"boss_veilwood_groveguard": "+6 max health, +5% ice resistance",
	&"boss_veilwood_bounty": "+5% experience, +6% gold",
	&"boss_cinder_kindling": "+7% fire damage, +0.03 cooldown recovery",
	&"boss_cinder_hearthguard": "+6 max health, +0.5 armour",
	&"boss_cinder_forge_edge": "+6% damage, +7% physical damage",
	&"boss_cinder_ember_crown": "+7% fire damage, +5% fire resistance",
	&"boss_storm_static_charge": "+0.03 cooldown recovery, +7% lightning damage",
	&"boss_storm_skyshroud": "+6 max health, +5% lightning resistance",
	&"boss_storm_thunder_focus": "+2% critical chance, +4% critical damage",
	&"boss_storm_overcharge": "+6% damage, +7% lightning damage",
	&"boss_tidal_deepcurrent": "+3% speed, +6% pickup radius",
	&"boss_tidal_tidegold": "+6% gold, +5% experience",
	&"boss_tidal_undertow": "+6% weapon area, +6% damage",
	&"boss_tidal_abyss_plate": "+6 max health, +5% physical resistance",
	&"boss_black_eclipse": "+2% critical chance, +4% critical damage",
	&"boss_black_voidlance": "+7% physical damage, +6% damage",
	&"boss_black_prism_recoil": "+6% weapon area, +4% critical damage",
	&"boss_black_meridian": "+3% speed, +6% pickup radius",
}
const BRANCHES: Dictionary = {
	"OFFENSE": ["might", "precision", "execution", "volley", "area", "fire", "ice", "lightning", "knockback", "physical_edge", "piercing", "ballistics", "catalyst", "armor_break", "tempered_edge", "quickdraw", "wide_arc", "critical_mass", "ember_fang", "glacial_edge", "storm_lance", "void_cut", "siege_round", "keening_edge", "forked_volley", "ember_oath", "glacial_oath", "storm_oath", "honed_edge", "execution_rite", "finishing_arc", "deep_cut", "cinderbrand", "flare_step", "frostbrand", "shattercold", "stormbrand", "voltaic_rhythm", "double_tap", "swift_flurry", "rifle_pace", "hunt_step", "execution_surge"],
	"SURVIVAL": ["vitality", "aegis", "revive", "physical_ward", "fire_ward", "evasion", "regeneration", "last_stand", "cursed_plate", "frost_ward", "lightning_ward", "iron_heart", "moving_guard", "ember_skin", "oathshield", "refuge", "stone_blood", "elemental_aegis", "windstep", "second_pulse", "sparkshrine", "fortified_frame", "tower_guard", "molten_aegis", "glacial_aegis", "voltaic_aegis", "all_weather", "fleet_guard", "stormfoot", "pulse_battery", "siphon_guard", "frontier_survival", "cinder_kin", "briar_kin", "storm_kin", "oath_of_continuity"],
	"EXPEDITION": ["boots", "haste", "wisdom", "reroll", "reserve", "pickup", "gold", "banish", "trinket_slot", "beacon_focus", "contract_scribe", "cache_salvage", "early_evolution", "event_surveyor", "trailblazer", "astral_lens", "fortune_finder", "deep_pockets", "swift_harvest", "guiding_star", "vanguard_steps", "wayfarer_stride", "salvager_sense", "trail_clock", "open_quiver", "far_scout", "long_road", "swift_cache", "measured_march", "split_the_trail", "star_chart", "dust_road", "salvage_ledger", "field_reserve", "far_reach", "pacer_ritual", "salvage_sprint", "clockwork_trek", "horizon_sight", "wayfarer_cache", "prismatic_horizon"],
	"RISK": ["curse", "glass_cannon", "gilded_famine", "redline", "blood_oath", "fever_pitch", "storm_pact", "frozen_bargain", "gilded_danger", "abyss_hunger", "dangerous_ambition", "barbed_pact", "ember_gamble", "frost_gamble", "storm_gamble", "crimson_ambition", "gilded_edge", "brutal_reflex", "ember_surge", "frost_surge", "storm_surge", "redline_reprise", "cursed_purse", "ember_reverie", "glacial_reverie", "storm_reverie", "crimson_reverie", "mercury_malice", "deep_greed", "cataclysmic_pact"],
	"BOSSES": ["boss_veilwood", "boss_cinder_reach", "boss_storm_citadel", "boss_tidal_maw", "boss_black_aurora", "boss_veilwood_edge", "boss_storm_ward", "boss_tidal_greed", "boss_veilwood_bloom", "boss_cinder_crown", "boss_storm_conduit", "boss_tidal_shell", "boss_aurora_prism", "boss_cinder_ash", "boss_veilwood_heartwood", "boss_veilwood_deeproots", "boss_veilwood_groveguard", "boss_veilwood_bounty", "boss_cinder_kindling", "boss_cinder_hearthguard", "boss_cinder_forge_edge", "boss_cinder_ember_crown", "boss_storm_static_charge", "boss_storm_skyshroud", "boss_storm_thunder_focus", "boss_storm_overcharge", "boss_tidal_deepcurrent", "boss_tidal_tidegold", "boss_tidal_undertow", "boss_tidal_abyss_plate", "boss_black_eclipse", "boss_black_voidlance", "boss_black_prism_recoil", "boss_black_meridian"],
}

const UPGRADE_REQUIRES: Dictionary = {
	"precision": {"might": 5},
	"execution": {"precision": 2},
	"volley": {"might": 10},
	"area": {"might": 5},
	"fire": {"precision": 2},
	"ice": {"precision": 2},
	"lightning": {"precision": 2},
	"knockback": {"execution": 2},
	"aegis": {"vitality": 5},
	"revive": {"aegis": 2},
	"physical_ward": {"vitality": 5},
	"fire_ward": {"aegis": 2},
	"haste": {"boots": 5},
	"wisdom": {"boots": 2},
	"reroll": {"boots": 1},
	"reserve": {"boots": 3},
	"pickup": {"boots": 2},
	"gold": {"wisdom": 2},
	"banish": {"reroll": 2},
	"trinket_slot": {"reserve": 3},
	"boss_veilwood": {"wisdom": 2},
	"boss_cinder_reach": {"fire": 2},
	"boss_storm_citadel": {"haste": 2},
	"boss_tidal_maw": {"pickup": 2},
	"boss_black_aurora": {"precision": 3},
	"physical_edge": {"might": 5},
	"piercing": {"precision": 2},
	"ballistics": {"area": 2},
	"catalyst": {"execution": 3},
	"armor_break": {"execution": 3},
	"evasion": {"vitality": 5},
	"regeneration": {"aegis": 2},
	"last_stand": {"physical_ward": 2},
	"cursed_plate": {"aegis": 3},
	"beacon_focus": {"wisdom": 2},
	"contract_scribe": {"gold": 2},
	"cache_salvage": {"pickup": 2},
	"early_evolution": {"haste": 2},
	"event_surveyor": {"beacon_focus": 2},
	"glass_cannon": {"curse": 2},
	"gilded_famine": {"curse": 2},
	"redline": {"curse": 3},
	"boss_veilwood_edge": {"might": 5},
	"boss_storm_ward": {"haste": 2},
	"boss_tidal_greed": {"pickup": 2},
	"tempered_edge": {"physical_edge": 1},
	"quickdraw": {"ballistics": 2},
	"wide_arc": {"area": 2},
	"critical_mass": {"execution": 2},
	"ember_fang": {"fire": 2},
	"glacial_edge": {"ice": 2},
	"storm_lance": {"lightning": 2},
	"void_cut": {"critical_mass": 2},
	"siege_round": {"wide_arc": 2},
	"frost_ward": {"physical_ward": 1},
	"lightning_ward": {"fire_ward": 1},
	"iron_heart": {"vitality": 5},
	"moving_guard": {"iron_heart": 2},
	"ember_skin": {"fire_ward": 2},
	"oathshield": {"aegis": 2},
	"refuge": {"frost_ward": 2},
	"trailblazer": {"boots": 3},
	"astral_lens": {"wisdom": 2},
	"fortune_finder": {"gold": 2},
	"deep_pockets": {"reserve": 2},
	"swift_harvest": {"pickup": 2},
	"guiding_star": {"astral_lens": 2},
	"vanguard_steps": {"trailblazer": 2},
	"blood_oath": {"curse": 2},
	"fever_pitch": {"curse": 2},
	"storm_pact": {"curse": 2},
	"frozen_bargain": {"curse": 2},
	"gilded_danger": {"curse": 2},
	"abyss_hunger": {"curse": 2},
	"boss_veilwood_bloom": {"boss_veilwood": 2},
	"boss_cinder_crown": {"boss_cinder_reach": 2},
	"boss_storm_conduit": {"boss_storm_citadel": 2},
	"boss_tidal_shell": {"boss_tidal_maw": 2},
	"boss_aurora_prism": {"boss_black_aurora": 2},
	"boss_cinder_ash": {"boss_cinder_crown": 2},
	&"honed_edge": {&"keening_edge": 2},
	&"execution_rite": {&"execution": 3},
	&"finishing_arc": {&"execution_rite": 2},
	&"deep_cut": {&"finishing_arc": 2},
	&"cinderbrand": {&"ember_oath": 2},
	&"flare_step": {&"cinderbrand": 2},
	&"frostbrand": {&"glacial_oath": 2},
	&"shattercold": {&"frostbrand": 2},
	&"stormbrand": {&"storm_oath": 2},
	&"voltaic_rhythm": {&"stormbrand": 2},
	&"double_tap": {&"forked_volley": 1},
	&"swift_flurry": {&"double_tap": 2},
	&"rifle_pace": {&"quickdraw": 2},
	&"execution_surge": {&"execution_rite": 2},
	&"fortified_frame": {&"stone_blood": 2},
	&"tower_guard": {&"iron_heart": 2},
	&"molten_aegis": {&"elemental_aegis": 2},
	&"glacial_aegis": {&"elemental_aegis": 2},
	&"voltaic_aegis": {&"elemental_aegis": 2},
	&"all_weather": {&"elemental_aegis": 3},
	&"fleet_guard": {&"windstep": 2},
	&"stormfoot": {&"fleet_guard": 2},
	&"pulse_battery": {&"second_pulse": 2},
	&"siphon_guard": {&"pulse_battery": 2},
	&"frontier_survival": {&"vanguard_steps": 2},
	&"cinder_kin": {&"ember_fang": 2},
	&"briar_kin": {&"glacial_edge": 2},
	&"storm_kin": {&"storm_lance": 2},
	&"oath_of_continuity": {&"iron_heart": 2},
	&"long_road": {&"wayfarer_stride": 2},
	&"swift_cache": {&"salvager_sense": 2},
	&"measured_march": {&"trail_clock": 2},
	&"split_the_trail": {&"open_quiver": 1},
	&"star_chart": {&"far_scout": 2},
	&"dust_road": {&"boots": 3},
	&"salvage_ledger": {&"gold": 2},
	&"field_reserve": {&"wisdom": 2},
	&"far_reach": {&"pickup": 2},
	&"pacer_ritual": {&"long_road": 2},
	&"salvage_sprint": {&"swift_cache": 2},
	&"clockwork_trek": {&"measured_march": 2},
	&"horizon_sight": {&"star_chart": 2},
	&"wayfarer_cache": {&"dust_road": 2},
	&"prismatic_horizon": {&"far_reach": 2},
	&"crimson_ambition": {&"dangerous_ambition": 2},
	&"gilded_edge": {&"dangerous_ambition": 2},
	&"brutal_reflex": {&"barbed_pact": 2},
	&"ember_surge": {&"ember_gamble": 2},
	&"frost_surge": {&"frost_gamble": 2},
	&"storm_surge": {&"storm_gamble": 2},
	&"redline_reprise": {&"redline": 3},
	&"cursed_purse": {&"gilded_edge": 2},
	&"ember_reverie": {&"ember_surge": 2},
	&"glacial_reverie": {&"frost_surge": 2},
	&"storm_reverie": {&"storm_surge": 2},
	&"crimson_reverie": {&"crimson_ambition": 2},
	&"mercury_malice": {&"brutal_reflex": 2},
	&"deep_greed": {&"cursed_purse": 2},
	&"cataclysmic_pact": {&"storm_reverie": 2},
	&"boss_veilwood_heartwood": {&"vitality": 10},
	&"boss_veilwood_deeproots": {&"boots": 8},
	&"boss_veilwood_groveguard": {&"boss_veilwood_heartwood": 2},
	&"boss_veilwood_bounty": {&"boss_veilwood_deeproots": 3},
	&"boss_cinder_kindling": {&"fire": 3},
	&"boss_cinder_hearthguard": {&"aegis": 3},
	&"boss_cinder_forge_edge": {&"execution": 3},
	&"boss_cinder_ember_crown": {&"boss_cinder_kindling": 3},
	&"boss_storm_static_charge": {&"haste": 3},
	&"boss_storm_skyshroud": {&"lightning_ward": 2},
	&"boss_storm_thunder_focus": {&"precision": 4},
	&"boss_storm_overcharge": {&"boss_storm_static_charge": 3},
	&"boss_tidal_deepcurrent": {&"pickup": 3},
	&"boss_tidal_tidegold": {&"wisdom": 5},
	&"boss_tidal_undertow": {&"boss_tidal_deepcurrent": 2},
	&"boss_tidal_abyss_plate": {&"boss_tidal_tidegold": 3},
	&"boss_black_eclipse": {&"precision": 4},
	&"boss_black_voidlance": {&"might": 10},
	&"boss_black_prism_recoil": {&"boss_black_eclipse": 2},
	&"boss_black_meridian": {&"boss_black_voidlance": 3},
}
const MODES: Array[String] = ["expedition", "daily", "bossrush", "endless"]
# What a fresh install starts with. Clearing the save restores exactly this list.
# Ranger is the one keeper nobody has to earn; the other twelve are awakened by
# clearing the ground that names them, or by the milestone in MILESTONE_UNLOCKS.
const FRESH_UNLOCKED: Array[String] = ["Ranger"]
var gold: int = 0
var bonuses: Dictionary = {&"keening_edge": 0, &"forked_volley": 0, &"ember_oath": 0, &"glacial_oath": 0, &"storm_oath": 0, &"honed_edge": 0, &"execution_rite": 0, &"finishing_arc": 0, &"deep_cut": 0, &"cinderbrand": 0, &"flare_step": 0, &"frostbrand": 0, &"shattercold": 0, &"stormbrand": 0, &"voltaic_rhythm": 0, &"double_tap": 0, &"swift_flurry": 0, &"rifle_pace": 0, &"hunt_step": 0, &"execution_surge": 0, &"stone_blood": 0, &"elemental_aegis": 0, &"windstep": 0, &"second_pulse": 0, &"sparkshrine": 0, &"fortified_frame": 0, &"tower_guard": 0, &"molten_aegis": 0, &"glacial_aegis": 0, &"voltaic_aegis": 0, &"all_weather": 0, &"fleet_guard": 0, &"stormfoot": 0, &"pulse_battery": 0, &"siphon_guard": 0, &"frontier_survival": 0, &"cinder_kin": 0, &"briar_kin": 0, &"storm_kin": 0, &"oath_of_continuity": 0, &"wayfarer_stride": 0, &"salvager_sense": 0, &"trail_clock": 0, &"open_quiver": 0, &"far_scout": 0, &"long_road": 0, &"swift_cache": 0, &"measured_march": 0, &"split_the_trail": 0, &"star_chart": 0, &"dust_road": 0, &"salvage_ledger": 0, &"field_reserve": 0, &"far_reach": 0, &"pacer_ritual": 0, &"salvage_sprint": 0, &"clockwork_trek": 0, &"horizon_sight": 0, &"wayfarer_cache": 0, &"prismatic_horizon": 0, &"dangerous_ambition": 0, &"barbed_pact": 0, &"ember_gamble": 0, &"frost_gamble": 0, &"storm_gamble": 0, &"crimson_ambition": 0, &"gilded_edge": 0, &"brutal_reflex": 0, &"ember_surge": 0, &"frost_surge": 0, &"storm_surge": 0, &"redline_reprise": 0, &"cursed_purse": 0, &"ember_reverie": 0, &"glacial_reverie": 0, &"storm_reverie": 0, &"crimson_reverie": 0, &"mercury_malice": 0, &"deep_greed": 0, &"cataclysmic_pact": 0, &"boss_veilwood_heartwood": 0, &"boss_veilwood_deeproots": 0, &"boss_veilwood_groveguard": 0, &"boss_veilwood_bounty": 0, &"boss_cinder_kindling": 0, &"boss_cinder_hearthguard": 0, &"boss_cinder_forge_edge": 0, &"boss_cinder_ember_crown": 0, &"boss_storm_static_charge": 0, &"boss_storm_skyshroud": 0, &"boss_storm_thunder_focus": 0, &"boss_storm_overcharge": 0, &"boss_tidal_deepcurrent": 0, &"boss_tidal_tidegold": 0, &"boss_tidal_undertow": 0, &"boss_tidal_abyss_plate": 0, &"boss_black_eclipse": 0, &"boss_black_voidlance": 0, &"boss_black_prism_recoil": 0, &"boss_black_meridian": 0, "might": 0, "precision": 0, "execution": 0, "volley": 0, "area": 0, "fire": 0, "ice": 0, "lightning": 0, "knockback": 0, "vitality": 0, "aegis": 0, "revive": 0, "physical_ward": 0, "fire_ward": 0, "boots": 0, "haste": 0, "wisdom": 0, "reroll": 0, "reserve": 0, "pickup": 0, "gold": 0, "banish": 0, "trinket_slot": 0, "curse": 0, "boss_veilwood": 0, "boss_cinder_reach": 0, "boss_storm_citadel": 0, "boss_tidal_maw": 0, "boss_black_aurora": 0, "physical_edge": 0, "piercing": 0, "ballistics": 0, "catalyst": 0, "armor_break": 0, "evasion": 0, "regeneration": 0, "last_stand": 0, "cursed_plate": 0, "beacon_focus": 0, "contract_scribe": 0, "cache_salvage": 0, "early_evolution": 0, "event_surveyor": 0, "glass_cannon": 0, "gilded_famine": 0, "redline": 0, "boss_veilwood_edge": 0, "boss_storm_ward": 0, "boss_tidal_greed": 0,
	"tempered_edge": 0, "quickdraw": 0, "wide_arc": 0, "critical_mass": 0, "ember_fang": 0, "glacial_edge": 0, "storm_lance": 0, "void_cut": 0, "siege_round": 0,
	"frost_ward": 0, "lightning_ward": 0, "iron_heart": 0, "moving_guard": 0, "ember_skin": 0, "oathshield": 0, "refuge": 0,
	"trailblazer": 0, "astral_lens": 0, "fortune_finder": 0, "deep_pockets": 0, "swift_harvest": 0, "guiding_star": 0, "vanguard_steps": 0,
	"blood_oath": 0, "fever_pitch": 0, "storm_pact": 0, "frozen_bargain": 0, "gilded_danger": 0, "abyss_hunger": 0,
	"boss_veilwood_bloom": 0, "boss_cinder_crown": 0, "boss_storm_conduit": 0, "boss_tidal_shell": 0, "boss_aurora_prism": 0, "boss_cinder_ash": 0}
var unlocked: Array[String] = FRESH_UNLOCKED.duplicate()
var region: int = 0
var difficulty: int = 0
var launching: bool = false
var selected: String = "Ranger"
var save_error: String = ""
var future_version: bool = false
var mode: String = "expedition"
var seed_override: int = 0
var daily_key: String = ""
var daily_best: int = 0
var daily_best_ascension: int = 0
var progress: Dictionary = {}
var unlocked_achievements: Array[String] = []
var settings: Dictionary = {"shake": true, "damage": true, "aim": true, "pause": true, "palette": 0, "resolution": 0}

func _ready() -> void:
	GameEvents.regional_boss_defeated.connect(_regional_boss_defeated)
	load_save()
	apply_resolution()

func resolution_available(index: int) -> bool:
	if index < 0 or index >= RESOLUTIONS.size():
		return false
	if DisplayServer.get_name() == "headless":
		return true
	var screen: Vector2i = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	return RESOLUTIONS[index].x <= screen.x and RESOLUTIONS[index].y <= screen.y

func apply_resolution() -> void:
	var index: int = clampi(int(settings.get("resolution", 0)), 0, RESOLUTIONS.size() - 1)
	while index > 0 and not resolution_available(index):
		index -= 1
	settings["resolution"] = index
	if DisplayServer.get_name() == "headless":
		return
	var target: Vector2i = RESOLUTIONS[index]
	var screen: int = DisplayServer.window_get_current_screen()
	DisplayServer.window_set_size(target)
	DisplayServer.window_set_position(DisplayServer.screen_get_position(screen) + (DisplayServer.screen_get_size(screen) - target) / 2)

func reset_progress() -> void:
	progress.clear()
	unlocked_achievements.clear()

# Back to a fresh install: gold, the Observatory, keepers, records and the daily bests.
# Settings (screen shake, palette, rebinds) and audio volumes are preferences, not progress,
# so they survive. Tests call reset_progress(); this is the player-facing wipe.
func wipe_save() -> void:
	reset_progress()
	gold = 0
	for key in bonuses:
		bonuses[key] = 0
	unlocked = FRESH_UNLOCKED.duplicate()
	selected = "Ranger"
	region = 0
	difficulty = 0
	mode = "expedition"
	seed_override = 0
	daily_key = ""
	daily_best = 0
	daily_best_ascension = 0
	# A wipe is the one case where an unreadable or newer save must be overwritten, not preserved.
	future_version = false
	save_error = ""
	save_data()

func load_save() -> void:
	var cfg := ConfigFile.new()
	var error: Error = cfg.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		save_error = "Save could not be read; original file preserved."
		future_version = true
		return
	var version: int = int(cfg.get_value("save", "version", 0))
	if version > VERSION:
		future_version = true
		save_error = "Newer save version: saving disabled to preserve it."
		return
	# Version 0 migration: legacy balance was called coins, with no unlock list.
	gold = maxi(0, int(cfg.get_value("save", "gold", cfg.get_value("save", "coins", 0))))
	for key in bonuses:
		bonuses[key] = clampi(int(cfg.get_value("bonuses", key, 0)), 0, int(MAX[key]))
	for name in NEW_UNLOCKS:
		if bool(cfg.get_value("characters", name, false)) and not unlocked.has(name):
			unlocked.append(name)
	selected = str(cfg.get_value("save", "selected", "Ranger"))
	difficulty = clampi(int(cfg.get_value("save", "difficulty", 0)), 0, DIFFICULTIES.size() - 1)
	if not unlocked.has(selected):
		selected = "Ranger"
	mode = str(cfg.get_value("modes", "mode", "expedition"))
	if not MODES.has(mode):
		mode = "expedition"
	daily_key = str(cfg.get_value("modes", "daily_key", ""))
	daily_best = maxi(0, int(cfg.get_value("modes", "daily_best", 0)))
	daily_best_ascension = maxi(0, int(cfg.get_value("modes", "daily_best_ascension", 0)))
	for key in settings:
		settings[key] = cfg.get_value("settings", key, settings[key])
	if cfg.has_section("progress"):
		for key in cfg.get_section_keys("progress"):
			progress[key] = cfg.get_value("progress", key, 0)
	if cfg.has_section("achievements"):
		for name in cfg.get_section_keys("achievements"):
			if bool(cfg.get_value("achievements", name, false)) and not unlocked_achievements.has(name):
				unlocked_achievements.append(name)

func save_data() -> void:
	if future_version:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", VERSION)
	cfg.set_value("save", "gold", gold)
	cfg.set_value("save", "selected", selected)
	cfg.set_value("save", "difficulty", difficulty)
	for key in bonuses:
		cfg.set_value("bonuses", key, bonuses[key])
	for name in unlocked:
		cfg.set_value("characters", name, true)
	for key in settings:
		cfg.set_value("settings", key, settings[key])
	cfg.set_value("modes", "mode", mode)
	cfg.set_value("modes", "daily_key", daily_key)
	cfg.set_value("modes", "daily_best", daily_best)
	cfg.set_value("modes", "daily_best_ascension", daily_best_ascension)
	for key in progress:
		cfg.set_value("progress", key, progress[key])
	for name in unlocked_achievements:
		cfg.set_value("achievements", name, true)
	var temp: String = SAVE_PATH + ".tmp"
	var error: Error = cfg.save(temp)
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(SAVE_PATH))
	save_error = "" if error == OK else "Save failed (%s)." % error

func progress_add(key: String, amount: float) -> void:
	progress[key] = float(progress.get(key, 0.0)) + amount

func progress_max(key: String, value: float) -> void:
	progress[key] = maxf(float(progress.get(key, 0.0)), value)

func progress_add_dict(key: String, values: Dictionary) -> void:
	var current: Dictionary = progress.get(key, {})
	for id in values:
		current[id] = float(current.get(id, 0.0)) + float(values[id])
	progress[key] = current

func progress_of(key: String) -> float:
	return float(progress.get(key, 0.0))

func _regional_boss_defeated(region_id: String, _title: String) -> void:
	var defeated: Dictionary = progress.get("bosses_defeated", {})
	if float(defeated.get(region_id, 0.0)) > 0.0:
		return
	progress_add_dict("bosses_defeated", {region_id: 1.0})
	save_data()

func bank_run(amount: int, kills: int, seconds: float, caches_opened: int = 0, rooms_found: int = 0, won: bool = false, run_difficulty: int = 0) -> void:
	gold += amount
	progress_add("total_gold", amount)
	progress_add("total_kills", kills)
	progress_add("runs", 1)
	progress_add("caches", caches_opened)
	progress_add("rooms", rooms_found)
	progress_max("best_seconds", seconds)
	progress_max("best_kills", kills)
	if won:
		progress_add("wins", 1)
		progress_max("fastest_win", seconds if seconds > 0.0 else 0.0)
		# Recording the clear gates later grounds and awakens this ground's keeper.
		var ground: RegionData = Regions.get_region(region)
		progress_add_dict("regions_cleared", {ground.id: 1})
		awaken(ground.reward_character)
	for entry in MILESTONE_UNLOCKS:
		var reached: bool = false
		match String(entry.stat):
			"kills": reached = float(kills) >= float(entry.at)
			"caches": reached = float(caches_opened) >= float(entry.at)
			"rooms": reached = float(rooms_found) >= float(entry.at)
			"seconds": reached = seconds >= float(entry.at)
			"difficulty": reached = won and run_difficulty >= int(entry.at)
		if reached:
			awaken(String(entry.character))
	save_data()

# Awakening is idempotent and every route flows through here. Routes overlap on
# purpose (a deep ground clear also passes its kill milestone), so callers never
# have to check the roster first.
func awaken(name: String) -> bool:
	if name.is_empty() or unlocked.has(name):
		return false
	unlocked.append(name)
	return true

# The ground whose clear awakens `name`, or null when only a milestone or the
# starting roster grants it. The region file owns the pairing; nothing else keeps
# a second copy that could drift out of date.
func keeper_ground(name: String) -> RegionData:
	for ground in Regions.all():
		if ground.reward_character == name:
			return ground
	return null

# Every keeper in the game: the starting roster plus everyone who must be earned.
func keeper_total() -> int:
	return FRESH_UNLOCKED.size() + NEW_UNLOCKS.size()

# The one-line route the keeper directory prints for a sealed keeper.
func keeper_unlock_hint(name: String) -> String:
	var ground: RegionData = keeper_ground(name)
	var milestone: String = ""
	for entry in MILESTONE_UNLOCKS:
		if String(entry.character) == name:
			milestone = String(entry.hint)
			break
	var routes: Array[String] = []
	if ground != null:
		routes.append("clear " + String(ground.name).capitalize())
	if not milestone.is_empty():
		routes.append(milestone)
	if routes.is_empty():
		return "Awakened from the start."
	return " or ".join(routes) + "."

func cleared_grounds() -> Dictionary:
	return progress.get("regions_cleared", {})

func region_cleared(id: String) -> int:
	return int(cleared_grounds().get(id, 0))

func cleared_ground_count() -> int:
	var total: int = 0
	for id in cleared_grounds():
		if int(cleared_grounds()[id]) > 0:
			total += 1
	return total

func region_unlocked(index: int) -> bool:
	if progress_of("admin_unlock_all") > 0.0:
		return true
	var rule: Dictionary = Regions.get_region(index).unlock
	match String(rule.get("type", "default")):
		"wins":
			return int(progress_of("wins")) >= int(rule.get("count", 1))
		"clear":
			return region_cleared(String(rule.get("id", ""))) > 0
		"grounds":
			return cleared_ground_count() >= int(rule.get("count", 1))
	return true

func admin_unlock_all() -> void:
	for name in NEW_UNLOCKS:
		if not unlocked.has(name):
			unlocked.append(name)
	for id in MAX:
		if id != "curse":
			bonuses[id] = MAX[id]
	for entry in Achievements.LIST:
		if not unlocked_achievements.has(entry.id):
			unlocked_achievements.append(entry.id)
	progress["admin_unlock_all"] = 1
	save_data()

func region_unlock_hint(index: int) -> String:
	if region_unlocked(index):
		return ""
	return Regions.get_region(index).unlock_hint

func unlocked_ground_count() -> int:
	var total: int = 0
	for i in Regions.count():
		if region_unlocked(i):
			total += 1
	return total

func cost(id: String) -> int:
	return int(50.0 * pow(1.6, int(bonuses.get(id, 0))))

func at_max(id: String) -> bool:
	return int(bonuses.get(id, 0)) >= int(MAX.get(id, 20))

func boss_upgrade_unlocked(id: String) -> bool:
	var region_id: String = String(BOSS_UPGRADE_REQUIRES.get(id, ""))
	if region_id.is_empty():
		return true
	var defeated: Dictionary = progress.get("bosses_defeated", {})
	return float(defeated.get(region_id, 0.0)) > 0.0

func boss_upgrade_hint(id: String) -> String:
	var region_id: String = String(BOSS_UPGRADE_REQUIRES.get(id, ""))
	if region_id.is_empty():
		return ""
	return "Defeat %s first." % String(BOSS_UPGRADE_NAMES.get(region_id, region_id))

func upgrade_unlocked(id: String) -> bool:
	if int(bonuses.get(id, 0)) > 0:
		return true
	if not boss_upgrade_unlocked(id):
		return false
	for required in UPGRADE_REQUIRES.get(id, {}):
		if int(bonuses.get(required, 0)) < int(UPGRADE_REQUIRES[id][required]):
			return false
	return true

func upgrade_requirement(id: String) -> String:
	var requirements: Dictionary = UPGRADE_REQUIRES.get(id, {})
	if requirements.is_empty():
		return ""
	var parts: Array[String] = []
	for required in requirements:
		parts.append("%s %d" % [String(required).capitalize(), int(requirements[required])])
	return "Needs " + ", ".join(parts)

func buy(id: String) -> bool:
	if not bonuses.has(id) or not upgrade_unlocked(id) or at_max(id) or gold < cost(id):
		return false
	gold -= cost(id)
	bonuses[id] += 1
	save_data()
	return true

func curse_level() -> int:
	return int(bonuses.get("curse", 0))

func revives() -> int:
	return int(bonuses.get("revive", 0))

func starting_gold() -> int:
	return int(bonuses.get("reserve", 0)) * 40 + int(bonuses.get("deep_pockets", 0)) * 25

func daily_seed() -> int:
	var date: Dictionary = Time.get_date_dict_from_system()
	var key: String = "%04d%02d%02d" % [int(date.year), int(date.month), int(date.day)]
	var value: int = 0
	for i in key.length():
		value = (value * 31 + key.unicode_at(i)) & 0x7fffffff
	return value

func refresh_daily_key() -> String:
	var date: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]

func set_mode(next: String) -> void:
	mode = next if MODES.has(next) else "expedition"

func mode_title() -> String:
	match mode:
		"daily": return "DAILY CHALLENGE"
		"bossrush": return "GUARDIAN GAUNTLET"
		"endless": return "ENDLESS ASCENT"
	return "EXPEDITION"

func apply(stats: StatsComponent) -> void:
	if selected == "Artificer":
		stats.set_bonus(&"character", &"projectiles", 1.0, 0.0)
		stats.set_bonus(&"character_frail", &"max_health", -10.0, 0.0)
	elif selected == "Pathfinder":
		stats.set_bonus(&"character", &"speed", 0.0, 0.2)
		stats.set_bonus(&"character_frail", &"max_health", -15.0, 0.0)
	elif selected == "Cinderkeeper":
		stats.set_bonus(&"character", &"mult_fire", 0.0, 0.2)
		stats.set_bonus(&"character_frail", &"max_health", -10.0, 0.0)
	elif selected == "Frostweaver":
		stats.set_bonus(&"character", &"mult_ice", 0.0, 0.2)
		stats.set_bonus(&"character_slow", &"speed", 0.0, -0.08)
	elif selected == "Salvager":
		stats.set_bonus(&"character", &"pickup", 0.0, 0.3)
		stats.set_bonus(&"character_frail", &"max_health", -15.0, 0.0)
	elif selected == "Archivist":
		stats.set_bonus(&"character", &"area", 0.0, 0.2)
		stats.set_bonus(&"character_slow", &"speed", 0.0, -0.08)
	elif selected == "Hexblade":
		stats.set_bonus(&"character", &"crit_chance", 0.12, 0.0)
		stats.set_bonus(&"character_frail", &"max_health", -10.0, 0.0)
	elif selected == "Eclipse":
		stats.set_bonus(&"character", &"damage", 0.0, 0.25)
		stats.set_bonus(&"character_frail", &"max_health", -30.0, 0.0)
	elif selected == "Ravager":
		stats.set_bonus(&"character", &"crit_damage", 0.4, 0.0)
		stats.set_bonus(&"character_edge", &"armour", 2.0, 0.0)
		stats.set_bonus(&"character_slow", &"speed", 0.0, -0.06)
	elif selected == "Glazier":
		stats.set_bonus(&"character", &"projectiles", 1.0, 0.0)
		stats.set_bonus(&"character_dampen", &"damage", 0.0, -0.15)
		stats.set_bonus(&"character_frail", &"max_health", -10.0, 0.0)
	# A keeper with more than one bonus needs a distinct source per stat. StatsComponent
	# keys sources by name, so two set_bonus calls sharing &"character" leave only the
	# last one standing -- the earlier bonus is lost with no error. Every multi-bonus
	# keeper below therefore names its own secondary sources.
	elif selected == "Fenwalker":
		stats.set_bonus(&"character", &"pickup", 0.0, 0.25)
		stats.set_bonus(&"character_haste", &"cdr", 0.05, 0.0)
		stats.set_bonus(&"character_frail", &"max_health", -10.0, 0.0)
	elif selected == "Starwright":
		stats.set_bonus(&"character", &"area", 0.0, 0.2)
		stats.set_bonus(&"character_scholar", &"xp", 0.0, 0.18)
		stats.set_bonus(&"character_frail", &"max_health", -12.0, 0.0)
	elif selected == "Veilbinder":
		stats.set_bonus(&"character", &"mult_physical", 0.0, 0.2)
		stats.set_bonus(&"character_precision", &"crit_chance", 0.04, 0.0)
		stats.set_bonus(&"character_frail", &"max_health", -10.0, 0.0)
	elif selected == "Ashcaller":
		stats.set_bonus(&"character", &"mult_fire", 0.0, 0.2)
		stats.set_bonus(&"character_greed", &"gold", 0.0, 0.12)
		stats.set_bonus(&"character_slow", &"speed", 0.0, -0.05)
	elif selected == "Stormwright":
		stats.set_bonus(&"character", &"mult_lightning", 0.0, 0.25)
		stats.set_bonus(&"character_haste", &"cdr", 0.04, 0.0)
		stats.set_bonus(&"character_frail", &"max_health", -15.0, 0.0)
	elif selected == "Brinelord":
		stats.set_bonus(&"character", &"resist_physical", 0.1, 0.0)
		stats.set_bonus(&"character_ward", &"resist_true", 0.1, 0.0)
		stats.set_bonus(&"character_edge", &"armour", 1.0, 0.0)
		stats.set_bonus(&"character_slow", &"speed", 0.0, -0.08)
	elif selected == "Polaris":
		stats.set_bonus(&"character", &"mult_true", 0.0, 0.25)
		stats.set_bonus(&"character_scholar", &"xp", 0.0, 0.1)
		stats.set_bonus(&"character_frail", &"max_health", -20.0, 0.0)
	# Ground bias is data-driven: each region file lists its stat trade-offs.
	var ground: RegionData = Regions.get_region(region)
	for entry in ground.bonus:
		var key: StringName = StringName(entry.get("stat", ""))
		stats.set_bonus(StringName("region_%s_%s" % [ground.id, String(key)]), key, float(entry.get("flat", 0.0)), float(entry.get("percent", 0.0)))
	stats.set_bonus(&"meta_might", &"damage", 0.0, int(bonuses.might) * 0.03)
	stats.set_bonus(&"meta_precision", &"crit_chance", int(bonuses.get("precision", 0)) * 0.015, 0.0)
	stats.set_bonus(&"meta_execution", &"crit_damage", int(bonuses.get("execution", 0)) * 0.08, 0.0)
	stats.set_bonus(&"meta_volley", &"projectiles", float(bonuses.get("volley", 0)), 0.0)
	stats.set_bonus(&"meta_area", &"area", 0.0, float(bonuses.get("area", 0)) * 0.10)
	stats.set_bonus(&"meta_fire", &"mult_fire", 0.0, float(bonuses.get("fire", 0)) * 0.10)
	stats.set_bonus(&"meta_ice", &"mult_ice", 0.0, float(bonuses.get("ice", 0)) * 0.10)
	stats.set_bonus(&"meta_lightning", &"mult_lightning", 0.0, float(bonuses.get("lightning", 0)) * 0.10)
	stats.set_bonus(&"meta_vitality", &"max_health", int(bonuses.vitality) * 5.0, 0.0)
	stats.set_bonus(&"meta_aegis", &"armour", float(bonuses.get("aegis", 0)), 0.0)
	stats.set_bonus(&"meta_physical_ward", &"resist_physical", float(bonuses.get("physical_ward", 0)) * 0.08, 0.0)
	stats.set_bonus(&"meta_fire_ward", &"resist_fire", float(bonuses.get("fire_ward", 0)) * 0.08, 0.0)
	stats.set_bonus(&"meta_boots", &"speed", 0.0, int(bonuses.boots) * 0.02)
	stats.set_bonus(&"meta_haste", &"cdr", float(bonuses.get("haste", 0)) * 0.03, 0.0)
	stats.set_bonus(&"meta_wisdom", &"xp", 0.0, int(bonuses.get("wisdom", 0)) * 0.08)
	stats.set_bonus(&"meta_pickup", &"pickup", 0.0, float(bonuses.get("pickup", 0)) * 0.20)
	stats.set_bonus(&"meta_gold", &"gold", 0.0, float(bonuses.get("gold", 0)) * 0.10)
	stats.set_bonus(&"meta_curse", &"curse", float(curse_level()), 0.0)
	stats.set_bonus(&"meta_boss_veilwood", &"xp", 0.0, float(bonuses.get("boss_veilwood", 0)) * 0.08)
	stats.set_bonus(&"meta_boss_cinder_reach", &"mult_fire", 0.0, float(bonuses.get("boss_cinder_reach", 0)) * 0.10)
	stats.set_bonus(&"meta_boss_storm_citadel", &"cdr", float(bonuses.get("boss_storm_citadel", 0)) * 0.03, 0.0)
	stats.set_bonus(&"meta_boss_tidal_maw", &"pickup", 0.0, float(bonuses.get("boss_tidal_maw", 0)) * 0.15)
	stats.set_bonus(&"meta_boss_black_aurora", &"crit_damage", 0.0, float(bonuses.get("boss_black_aurora", 0)) * 0.08)
	stats.set_bonus(&"meta_physical_edge", &"mult_physical", 0.0, float(bonuses.get("physical_edge", 0)) * 0.1)
	stats.set_bonus(&"meta_armor_break", &"mult_physical", 0.0, float(bonuses.get("armor_break", 0)) * 0.1)
	stats.set_bonus(&"meta_cursed_plate", &"armour", float(bonuses.get("cursed_plate", 0)) * 0.5 * curse_level(), 0.0)
	stats.set_bonus(&"meta_beacon_focus", &"xp", 0.0, float(bonuses.get("beacon_focus", 0)) * 0.08)
	stats.set_bonus(&"meta_contract_scribe", &"gold", 0.0, float(bonuses.get("contract_scribe", 0)) * 0.1)
	stats.set_bonus(&"meta_cache_salvage", &"pickup", 0.0, float(bonuses.get("cache_salvage", 0)) * 0.2)
	stats.set_bonus(&"meta_early_evolution", &"cdr", float(bonuses.get("early_evolution", 0)) * 0.03, 0.0)
	stats.set_bonus(&"meta_event_surveyor", &"xp", 0.0, float(bonuses.get("event_surveyor", 0)) * 0.08)
	stats.set_bonus(&"meta_boss_veilwood_edge", &"mult_physical", 0.0, float(bonuses.get("boss_veilwood_edge", 0)) * 0.1)
	stats.set_bonus(&"meta_boss_storm_ward", &"cdr", float(bonuses.get("boss_storm_ward", 0)) * 0.03, 0.0)
	stats.set_bonus(&"meta_boss_tidal_greed", &"pickup", 0.0, float(bonuses.get("boss_tidal_greed", 0)) * 0.2)
	stats.set_bonus(&"meta_glass_cannon", &"damage", 0.0, float(bonuses.get("glass_cannon", 0)) * 0.1)
	stats.set_bonus(&"meta_glass_cannon_curse", &"curse", float(bonuses.get("glass_cannon", 0)), 0.0)
	stats.set_bonus(&"meta_gilded_famine", &"gold", 0.0, float(bonuses.get("gilded_famine", 0)) * 0.1)
	stats.set_bonus(&"meta_gilded_famine_curse", &"curse", float(bonuses.get("gilded_famine", 0)), 0.0)
	stats.set_bonus(&"meta_redline", &"speed", 0.0, float(bonuses.get("redline", 0)) * 0.08)
	stats.set_bonus(&"meta_redline_curse", &"curse", float(bonuses.get("redline", 0)), 0.0)
	for id in NEW_STAT_BONUSES:
		var rank: float = float(bonuses.get(id, 0))
		if rank <= 0.0:
			continue
		for effect in NEW_STAT_BONUSES[id]:
			var stat: StringName = StringName(effect[0])
			stats.set_bonus(StringName("meta_%s_%s" % [id, String(stat)]), stat, rank * float(effect[1]), rank * float(effect[2]))
	if selected == "Warden":
		stats.set_bonus(&"character", &"max_health", 40.0, 0.0)
		stats.set_bonus(&"character_slow", &"speed", 0.0, -0.08)
	elif selected == "Arcanist":
		stats.set_bonus(&"character", &"damage", 0.0, 0.15)
		stats.set_bonus(&"character_frail", &"max_health", -20.0, 0.0)
