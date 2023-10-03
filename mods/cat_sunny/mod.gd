extends ContentInfo


const MODUTILS = {
	"updates": "https://gist.githubusercontent.com/Yukitty/f113b1e2c11faad763a47ebc0a867643/raw/updates.json"
}

var CHARACTER_SUNNY: Character

const WORLD_SCENE_CALLBACKS: Dictionary = {
	"res://world/maps/interiors/GramophoneInterior.tscn":
		"_on_GramophoneInterior_ready",
}

# Script-modified Resources MUST remain in some
# global var, or else the changes will be lost.
# This includes take_over_path getting reverted.
var res_cache: Array


func init_content() -> void:
	var res: Resource

	# Add translation strings
	TranslationServer.add_translation(preload("mod_strings.en.translation"))

	# World scene callbacks
	SceneManager.connect("scene_changed", self, "_on_SceneManager_scene_changed")
	SceneManager.connect("scene_change_starting", self, "_on_SceneManager_scene_changed", [], CONNECT_ONESHOT)

	# Finish initialization later
	assert(not SceneManager.preloader.singleton_setup_complete)
	yield(SceneManager.preloader, "singleton_setup_completed")

	# Add body_cat_sunny to battle parts
	_add_part_to_index(HumanLayersHelper.battle_layer_table.body, preload("body_cat_sunny.tscn"))

	# Duplicate vanilla world/body_sunny as body_cat_sunny
	res = load("res://sprites/characters/world/human_layers/body_sunny.json")
	res.duplicate()
	res.resource_path = "res://mods/cat_sunny/world/body_cat_sunny.tscn"
	_add_part_to_index(HumanLayersHelper.world_layer_table.body, res)

	# Duplicate vanilla world/arms_sunny as arms_cat_sunny
	res = load("res://sprites/characters/world/human_layers/arms_sunny.json")
	res.duplicate()
	res.resource_path = "res://mods/cat_sunny/world/arms_cat_sunny.tscn"
	_add_part_to_index(HumanLayersHelper.world_layer_table.arms, res)

	# I don't believe this is required. I don't know what it is used for.
#	if not "cat_sunny" in HumanLayersHelper.bodies:
#		HumanLayersHelper.bodies.push_back("cat_sunny")
#	assert("cat_sunny" in HumanLayersHelper.arms)

	# Late load Sunny's Character
	CHARACTER_SUNNY = load("res://mods/cat_sunny/character_sunny.tres")

	# Extend SunnyPunk
	res = load("res://mods/cat_sunny/SunnyPunk.tscn")
	res.take_over_path("res://world/recurring_npcs/SunnyPunk.tscn")
	res_cache.push_back(res)

	# Extend SwapPartnerCutscene
	res = load("res://mods/cat_sunny/cutscenes/SwapPartnerCutscene.tscn")
	res.take_over_path("res://nodes/partners/SwapPartnerCutscene.tscn")
	res_cache.push_back(res)

	# Extend Camping cutscene
	res = load("res://mods/cat_sunny/cutscenes/Camping.tscn")
	res.take_over_path("res://cutscenes/Camping.tscn")
	res_cache.push_back(res)

	# Extend PartnerArchangelReaction
	res = load("res://mods/cat_sunny/cutscenes/PartnerArchangelReaction.tscn")
	res.take_over_path("res://cutscenes/archangels/PartnerArchangelReaction.tscn")
	res_cache.push_back(res)

	res = load("res://mods/cat_sunny/cutscenes/PartnerArchangelReaction_CountInc.tscn")
	res.take_over_path("res://cutscenes/archangels/PartnerArchangelReaction_CountInc.tscn")
	res_cache.push_back(res)

	# Extend MissMimicSpawn_ChestInteract
	res = load("res://mods/cat_sunny/cutscenes/MissMimicSpawn_ChestInteract.tscn")
	res.take_over_path("res://cutscenes/passive_quests/MissMimicSpawn_ChestInteract.tscn")
	res_cache.push_back(res)

	# Add sunny to the global partners list
	SaveState.party.source_partners.push_back(CHARACTER_SUNNY)
	SaveState.party.initial_partner_levels[CHARACTER_SUNNY.partner_id] = 50

	# Sadly, party.setup() has already been called,
	# so we have no choice but to play catch-up.
	var p: Character = CHARACTER_SUNNY.duplicate()
	SaveState.party._make_tapes_unique(p)
	SaveState.party.partners.push_back(p)
	SaveState.party.unlocked_partners.push_back(p.partner_id)


func _add_part_to_index(index: LayerPartIndex, part: PackedScene) -> void:
	index.parts.push_back(part)
	# If _analyze hasn't been called yet, allow it to do the work
	if index._parts_by_name.empty():
		return
	# Post-analyze, add part names ourself.
	var name: String = index.get_part_name(part)
	index._parts_by_name[name] = part
	index.part_names.push_back(name)


func _on_SceneManager_scene_changed() -> void:
	var scene_path: String = SceneManager.current_scene.filename
	if scene_path in WORLD_SCENE_CALLBACKS:
		call(WORLD_SCENE_CALLBACKS[scene_path], SceneManager.current_scene)


func _on_GramophoneInterior_ready(scene: Node) -> void:
	var sunny := WarpTarget.new()
	sunny.name = CHARACTER_SUNNY.partner_id
	sunny.translation = Vector3(9.22, 2, -1.25)
	sunny.direction = "down"

	var unlocked_partner_spawner: Spatial = scene.get_node("UnlockedPartnerSpawner")
	unlocked_partner_spawner.add_child(sunny)
	unlocked_partner_spawner.spawn_partners()
