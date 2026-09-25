class_name Regions
extends RefCounted
# Loads and caches the region catalogue. Order defines the atlas order and the
# stable index stored in MetaProgression.region and in build codes.
const IDS: Array[String] = [
	"asterfall",
	"ember",
	"garden",
	"abyss",
	"spire",
	"rime",
	"storm",
	"ossuary",
	"vein",
	"mirror",
	"mire",
	"dunes",
	"bastion",
	"coast",
	"comet",
	"veilwood",
	"cinder_reach",
	"storm_citadel",
	"tidal_maw",
	"black_aurora",
]
const DEFAULT_UNLOCKED: int = 3
static var _cache: Array[RegionData] = []

static func all() -> Array[RegionData]:
	if _cache.is_empty():
		for id in IDS:
			_cache.append(load("res://data/regions/%s.tres" % id))
	return _cache

static func count() -> int:
	return IDS.size()

static func get_region(index: int) -> RegionData:
	var list: Array[RegionData] = all()
	return list[clampi(index, 0, list.size() - 1)]

static func index_of(id: String) -> int:
	return IDS.find(id)
