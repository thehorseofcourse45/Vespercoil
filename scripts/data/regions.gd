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
	"saltbound",
	"amberhold",
	"vesperine",
	"lodestone",
	"chancery",
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

static func guardian(region: RegionData) -> BossData:
	return load("res://data/bosses/regions/%s.tres" % region.id)

# Null when the ground has only one guardian, which is most of them.
static func guardian_alt(region: RegionData) -> BossData:
	if region.guardian_alt.is_empty():
		return null
	return load("res://data/bosses/regions/%s.tres" % region.guardian_alt)

# Every guardian a ground can field, standard one first. The atlas and the bestiary
# list this so an alternate is visible before it ambushes someone.
static func guardians(region: RegionData) -> Array[BossData]:
	var list: Array[BossData] = [guardian(region)]
	var alt: BossData = guardian_alt(region)
	if alt != null:
		list.append(alt)
	return list

# The ground's guardian for a given run. Two-guardian grounds alternate by seed, so
# the same ground is a different fight on a different expedition while staying
# reproducible from the seed alone (daily and weekly runs included).
static func guardian_for_seed(region: RegionData, run_seed: int) -> BossData:
	var alt: BossData = guardian_alt(region)
	if alt == null:
		return guardian(region)
	return alt if (run_seed + index_of(region.id)) % 2 != 0 else guardian(region)
