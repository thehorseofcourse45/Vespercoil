extends Node
# Thin Steamworks bridge. No SDK is bundled with the project, so every call is
# guarded: when the Steam singleton is absent (offline/dev builds) the layer is a
# no-op and achievements still unlock locally through MetaProgression.
var available: bool = false

func _ready() -> void:
	available = Engine.has_singleton("Steam")

func _steam() -> Object:
	return Engine.get_singleton("Steam") if available else null

func unlock(api_name: String) -> void:
	if available:
		_steam().call("unlockAchievement", api_name)

func set_stat(name: String, value: int) -> void:
	if available:
		_steam().call("setStat", name, value)

func store() -> void:
	if available:
		_steam().call("storeStats")

func status() -> String:
	return "STEAM CONNECTED" if available else "OFFLINE / LOCAL RECORDS"
