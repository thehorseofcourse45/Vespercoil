class_name ZoneCatalog
extends RefCounted

# Each ground owns six named districts. Tints are chosen for the district's material
# or atmosphere; the third value is its soft-terrain movement multiplier.
const ZONES: Dictionary = {
	"asterfall": [
		["FALLEN ORRERY", "78d5df", .95], ["METEOR GLASS", "82b7f0", .85],
		["STAR SCAR", "ac89eb", .75], ["LUNAR DUST", "b9c8cf", .9],
		["ECLIPSE COURT", "646cba", .7], ["AURORA RIM", "6ce7c9", 1.0]],
	"ember": [
		["EMBER FORGE", "f58a41", 1.0], ["CINDER CONDUIT", "dd5937", .8],
		["SLAG BASIN", "9c7663", .6], ["BRASS FURNACE", "d9ae54", .9],
		["ASH CHUTE", "a49b91", .7], ["MOLTEN HEART", "ffbd52", 1.0]],
	"garden": [
		["BLOOMING CLOISTER", "8dd57a", 1.0], ["THORN ARCADE", "668c5a", .65],
		["SPORE GROTTO", "b291c8", .6], ["ROOT MAZE", "827b53", .7],
		["LILY MIRROR", "76cbb5", .85], ["WILD CANOPY", "aedb69", .75]],
	"abyss": [
		["SABLE SHELF", "696c9e", .8], ["VOID TRENCH", "6b58aa", .55],
		["DARKWATER WELL", "568ca0", .7], ["ECHO CHASM", "a46ba5", .75],
		["OBSIDIAN LIP", "81828d", .9], ["NIGHTFALL PIT", "b75b81", .65]],
	"spire": [
		["GILDED ATRIUM", "e2c66e", 1.0], ["COIN VAULT", "dba34b", .85],
		["BRONZE ASCENT", "bc8562", .8], ["SUNLIT GALLERY", "f1d88c", 1.0],
		["TARNISHED WALK", "a9a276", .65], ["CROWN CHAMBER", "eab65e", .9]],
	"rime": [
		["FROSTFALL DRIFT", "9dcde8", .7], ["BLUE ICE SHELF", "65b6dc", .6],
		["SNOWBLIND PASS", "d8e4e8", .85], ["GLACIER THROAT", "7c9fc9", .55],
		["HOARFROST GROVE", "a8d9d3", .75], ["PALE CRYSTAL", "b3b8ee", .9]],
	"storm": [
		["THUNDER CROWN", "e8d86f", 1.0], ["BOLT SCAR", "8aaeee", .8],
		["TEMPEST EYE", "b394e8", .9], ["STATIC FIELD", "80d6d9", .65],
		["SKYFIRE RIDGE", "efb56b", .95], ["CLOUDBREAK", "b7c9e7", .75]],
	"ossuary": [
		["IVORY NAVE", "d9d0ae", .9], ["MARROW CRYPT", "b994a0", .65],
		["SPECTRAL CHOIR", "90c7c6", .8], ["BONE GALLERY", "c5bba3", .75],
		["BLOOD ALTAR", "c47b78", 1.0], ["PALE OSSUARY", "c6c8d2", .7]],
	"vein": [
		["CRIMSON ARTERY", "df7274", 1.0], ["IRON CLOT", "aa6b72", .7],
		["ROSE QUARTZ CUT", "d991b4", .9], ["SCARLET FISSURE", "e75b5b", .8],
		["HEMATIC POOL", "a36396", .55], ["RUBY HEART", "f6a078", .95]],
	"mirror": [
		["SILVER REFLECTION", "c4d8df", .9], ["GLASS LABYRINTH", "80c9d8", .7],
		["PRISM HALL", "bb9be5", 1.0], ["SHATTERED IMAGE", "94a5d8", .75],
		["MERCURY POOL", "9eb7ba", .6], ["RAINBOW FRACTURE", "e4a6c9", .85]],
	"mire": [
		["PEAT HOLLOW", "858b5c", .65], ["REED CHANNEL", "7eb29a", .8],
		["FALLOW POOL", "708f82", .55], ["FIREFLY FEN", "c3c477", 1.0],
		["RUSTED BOG", "b88963", .7], ["MOSS SINK", "83aa68", .6]],
	"dunes": [
		["SUNDERED RIDGE", "e2b36b", .9], ["RED SAND WASH", "d48363", .75],
		["MIRAGE BASIN", "a7c7ba", .8], ["GOLDEN WIND", "efd17d", 1.0],
		["SHADE CARAVAN", "ab9274", .7], ["SALT FLAT", "dcd5b2", .85]],
	"bastion": [
		["BRASS GEARWAY", "d3ab65", .9], ["STEEL PARADE", "9aafbd", .8],
		["COPPER ENGINE", "cc8869", 1.0], ["CLOCKFACE COURT", "e5cf89", .85],
		["OIL SUMP", "777f8b", .6], ["BLUE SPARK LINE", "77cbd9", .75]],
	"coast": [
		["DROWNED PIER", "7baaba", .7], ["SEAFOAM REACH", "9ddbc8", .9],
		["DEEP CURRENT", "6091bc", .55], ["SALTSPRAY WALK", "bed9d7", 1.0],
		["CORAL BREAK", "d990a0", .8], ["KELP CHANNEL", "6bb69e", .65]],
	"comet": [
		["COMET TAIL", "a6b6f4", .9], ["IMPACT GLASS", "83d0e3", .75],
		["FALLEN EMBER", "e8a378", 1.0], ["SKY DUST", "c6c3db", .8],
		["CRATER RIM", "9888c7", .7], ["RADIANT CORE", "d4b9f0", .95]],
	"veilwood": [
		["VEILED GROVE", "83c48b", .9], ["MOONFERN PATH", "a5c7b8", .8],
		["THORNED UNDERSTORY", "759c70", .65], ["WITCHLIGHT GLADE", "ab9bdd", 1.0],
		["MISTROOT HOLLOW", "77abb2", .7], ["HEARTWOOD RING", "c3bc7a", .85]],
	"cinder_reach": [
		["CINDER ROAD", "df7953", .9], ["FURNACE VENT", "f6a455", 1.0],
		["SMOLDERING CRAG", "b8655d", .75], ["BLACK ASH PLAIN", "a79b91", .65],
		["LAVA SPILL", "f3c365", .8], ["CHARRED GATE", "cf7c69", .7]],
	"storm_citadel": [
		["VOLT BATTLEMENT", "e6d777", .95], ["AZURE CONDUIT", "7bcde0", .8],
		["PURPLE CAPACITOR", "b396e4", .7], ["LIGHTNING KEEP", "d5c18d", 1.0],
		["CLOUD SPIRE", "a5bfdc", .75], ["THUNDER VAULT", "8d9be3", .85]],
	"tidal_maw": [
		["MAW CURRENT", "6793c8", .65], ["FOAMFANG SHOAL", "a4d7d5", .85],
		["ABYSSAL EDDY", "657bb4", .55], ["PEARL SHELF", "d0d6c2", .9],
		["TURQUOISE RIP", "71c4bd", 1.0], ["DROWNED GULLET", "758ca8", .7]],
	"black_aurora": [
		["DARK AURORA", "9b8bc8", .85], ["VOID MERIDIAN", "747bb7", .65],
		["ROSE NEBULA", "d895b2", .9], ["NIGHT PRISM", "a6b5d6", .75],
		["GHOSTLIGHT ARC", "7cc9bc", 1.0], ["ECLIPSE SHADOW", "bd88bb", .7]],
}

static func for_region(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in ZONES[id]:
		result.append({"name": entry[0], "tint": Color(entry[1]), "slow": entry[2]})
	return result
