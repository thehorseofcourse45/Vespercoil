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
	{"id": "bestiary", "title": "COMPLETE BESTIARY", "detail": "Defeat 5,000 vessels in total.", "stat": "total_kills", "target": 5000.0, "reward": 400}
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
