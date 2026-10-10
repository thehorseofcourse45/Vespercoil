extends Node
# Persistent achievements and the bestiary tally. Evaluated after every run from
# MetaProgression.progress, which RunManager and this node both feed.
const LIST: Array[Dictionary] = [
	{"id": "first_blood", "title": "FIRST BLOOD", "detail": "Defeat your first vessel.", "stat": "total_kills", "target": 1.0, "reward": 25},
	{"id": "slayer", "title": "SLAYER", "detail": "Defeat 1,000 vessels across all runs.", "stat": "total_kills", "target": 1000.0, "reward": 100},
	{"id": "centurion", "title": "CENTURION", "detail": "Defeat 250 vessels in a single run.", "stat": "best_kills", "target": 250.0, "reward": 75},
	{"id": "sanctum", "title": "SANCTUM", "detail": "Open 12 supply caches in total.", "stat": "caches", "target": 12.0, "reward": 75},
	{"id": "cartographer", "title": "CARTOGRAPHER", "detail": "Discover four hidden sites.", "stat": "rooms", "target": 4.0, "reward": 75},
	{"id": "prospector", "title": "PROSPECTOR", "detail": "Bank 5,000 gold in total.", "stat": "total_gold", "target": 5000.0, "reward": 150},
	{"id": "reactionary", "title": "REACTIONARY", "detail": "Trigger 25 elemental reactions.", "stat": "reactions", "target": 25.0, "reward": 75},
	{"id": "survivor", "title": "SURVIVOR", "detail": "Defeat the Last Coil.", "stat": "wins", "target": 1.0, "reward": 200},
	{"id": "nightmare", "title": "THE NIGHTMARE ENDS", "detail": "Win on Nightmare difficulty.", "stat": "nightmare_wins", "target": 1.0, "reward": 300},
	{"id": "gauntlet", "title": "GAUNTLET MASTER", "detail": "Clear the Guardian Gauntlet.", "stat": "bossrush_wins", "target": 1.0, "reward": 250},
	{"id": "ascendant", "title": "ASCENDANT", "detail": "Reach ascension 1 in Endless Ascent.", "stat": "best_ascension", "target": 1.0, "reward": 250},
	{"id": "bestiary", "title": "COMPLETE BESTIARY", "detail": "Defeat 5,000 vessels in total.", "stat": "total_kills", "target": 5000.0, "reward": 400},
	{"id": "groundbreaker", "title": "FIRST GROUND", "detail": "Clear any ground's guardian.", "stat": "grounds_cleared", "target": 1.0, "reward": 75},
	{"id": "pathmaker", "title": "PATHMAKER", "detail": "Clear five grounds.", "stat": "grounds_cleared", "target": 5.0, "reward": 150},
	{"id": "atlas_complete", "title": "THE WHOLE ATLAS", "detail": "Clear every ground.", "stat": "grounds_cleared", "target": 25.0, "reward": 500},
	{"id": "awakened_five", "title": "FIVE AWAKE", "detail": "Awaken five keepers.", "stat": "keepers_total", "target": 5.0, "reward": 125},
	{"id": "awakened_fifteen", "title": "MANY AWAKE", "detail": "Awaken fifteen keepers.", "stat": "keepers_total", "target": 15.0, "reward": 300},
	{"id": "roster_twenty_five", "title": "FULL ROSTER", "detail": "Awaken all twenty-five keepers.", "stat": "keepers_total", "target": 25.0, "reward": 600},
	{"id": "veteran", "title": "VETERAN", "detail": "Reach level 20 in a run.", "stat": "best_level", "target": 20.0, "reward": 100},
	{"id": "apex_vessel", "title": "APEX VESSEL", "detail": "Reach level 30 in a run.", "stat": "best_level", "target": 30.0, "reward": 300},
	{"id": "houndmaster", "title": "HOUNDMASTER", "detail": "Defeat 250 elites across all runs.", "stat": "elites", "target": 250.0, "reward": 150},
	{"id": "catalyst", "title": "CATALYST", "detail": "Trigger 100 elemental reactions.", "stat": "reactions", "target": 100.0, "reward": 200},
	{"id": "magnate", "title": "MAGNATE", "detail": "Bank 25,000 gold in total.", "stat": "total_gold", "target": 25000.0, "reward": 300},
	{"id": "reaper", "title": "REAPER", "detail": "Defeat 20,000 vessels across all runs.", "stat": "total_kills", "target": 20000.0, "reward": 350},
	{"id": "loopwalker", "title": "LOOPWALKER", "detail": "Reach ascension 3 in Endless Ascent.", "stat": "best_ascension", "target": 3.0, "reward": 300},
	{"id": "ladderbreaker", "title": "LADDERBREAKER", "detail": "Fell seven guardians in a single run.", "stat": "best_guardians", "target": 7.0, "reward": 250},
	{"id": "curator", "title": "CURATOR", "detail": "Open 60 supply caches in total.", "stat": "caches", "target": 60.0, "reward": 200},
	{"id": "delver", "title": "DELVER", "detail": "Discover twenty hidden sites.", "stat": "rooms", "target": 20.0, "reward": 200},
	{"id": "devoted", "title": "DEVOTED", "detail": "Win fourteen dailies.", "stat": "daily_wins", "target": 14.0, "reward": 300},
]
var pending_notices: Array[String] = []

func _ready() -> void:
	GameEvents.run_ended.connect(_run_ended)

func unlocked(id: String) -> bool:
	return MetaProgression.unlocked_achievements.has(id)

func progress_ratio(entry: Dictionary) -> float:
	var value: float = MetaProgression.progress_of(String(entry.stat))
	return clampf(value / maxf(1.0, float(entry.target)), 0.0, 1.0)

func record_run() -> void:
	var summary: Dictionary = RunManager.summary()
	MetaProgression.progress_add_dict("by_kind", summary.get("kills_by_kind", {}))
	MetaProgression.progress_max("best_ascension", float(RunManager.ascension))
	MetaProgression.progress_max("best_score", float(RunManager.score))
	MetaProgression.progress_max("best_guardians", float(RunManager.guardians))
	MetaProgression.progress_max("best_level", float(summary.get("level", 1)))
	MetaProgression.progress_add("elites", float(summary.get("elites", 0)))
	MetaProgression.progress_max("grounds_cleared", float(MetaProgression.cleared_ground_count()))
	MetaProgression.progress_max("keepers_total", float(MetaProgression.unlocked.size()))
	if bool(summary.get("victory", false)):
		if int(summary.get("difficulty", 0)) == 2:
			MetaProgression.progress_add("nightmare_wins", 1.0)
		if MetaProgression.mode == "bossrush":
			MetaProgression.progress_add("bossrush_wins", 1.0)
		if MetaProgression.mode == "daily":
			MetaProgression.progress_add("daily_wins", 1.0)
	evaluate()

func evaluate() -> Array:
	var fresh: Array = []
	for entry in LIST:
		var id: String = entry.id
		if unlocked(id):
			continue
		if MetaProgression.progress_of(String(entry.stat)) >= float(entry.target):
			MetaProgression.unlocked_achievements.append(id)
			MetaProgression.gold += int(entry.reward)
			GameEvents.achievement_unlocked.emit(id, entry.title)
			GameEvents.notice.emit("LEGACY SECURED / " + entry.title, "%s  +%d gold" % [entry.detail, int(entry.reward)], Color("d4b678"))
			Steam.unlock(id)
			fresh.append(id)
	if not fresh.is_empty():
		MetaProgression.save_data()
		Steam.set_stat("achievements", MetaProgression.unlocked_achievements.size())
		Steam.store()
	return fresh

func count() -> int:
	return MetaProgression.unlocked_achievements.size()

func _run_ended(_victory: bool) -> void:
	record_run()
