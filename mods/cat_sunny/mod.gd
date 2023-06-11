extends ContentInfo


var CHARACTER_SUNNY: Character

const WORLD_SCENE_CALLBACKS: Dictionary = {
	"res://world/maps/interiors/GramophoneInterior.tscn":
		"_on_GramophoneInterior_ready",
}

# Script-modified Resources MUST remain in some
# global var, or else the changes will be lost.
# This includes take_over_path getting reverted.
var swap_partner_cutscene: PackedScene
var sunny_punk: PackedScene
var camping: PackedScene
var partner_archangel_reaction: PackedScene
var partner_archangel_reaction_counter: PackedScene
var miss_mimic_spawn_chest_interact: PackedScene
var save_state_party: GDScript


func init_content() -> void:
	var res: Resource

	# Add translation strings
	TranslationServer.add_translation(preload("mod_strings.en.translation"))

	# World scene callbacks
	SceneManager.connect("scene_changed", self, "_on_SceneManager_scene_changed")
	SceneManager.connect("scene_change_starting", self, "_on_SceneManager_scene_changed", [], CONNECT_ONESHOT)

	# Extend SaveState.party (bootleg bugfix and Bonus Stickers)
	save_state_party = load("res://mods/cat_sunny/Party.gd")
	save_state_party.take_over_path("res://global/save_state/Party.gd")

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

	# I have no idea what this does, I'm GRASPING here
	if not "cat_sunny" in HumanLayersHelper.bodies:
		HumanLayersHelper.bodies.push_back("cat_sunny")
	assert("cat_sunny" in HumanLayersHelper.arms)

	# Late load Sunny's Character
	CHARACTER_SUNNY = load("res://mods/cat_sunny/character_sunny.tres")

	# Extend SunnyPunk
	sunny_punk = load("res://mods/cat_sunny/SunnyPunk.tscn")
	sunny_punk.take_over_path("res://world/recurring_npcs/SunnyPunk.tscn")

	# Extend SwapPartnerCutscene
	swap_partner_cutscene = load("res://mods/cat_sunny/cutscenes/SwapPartnerCutscene.tscn")
	swap_partner_cutscene.take_over_path("res://nodes/partners/SwapPartnerCutscene.tscn")

	# Extend Camping cutscene
	camping = load("res://mods/cat_sunny/cutscenes/Camping.tscn")
	camping.take_over_path("res://cutscenes/Camping.tscn")

	# Extend PartnerArchangelReaction
	partner_archangel_reaction = load("res://mods/cat_sunny/cutscenes/PartnerArchangelReaction.tscn")
	partner_archangel_reaction.take_over_path("res://cutscenes/archangels/PartnerArchangelReaction.tscn")
	partner_archangel_reaction_counter = load("res://mods/cat_sunny/cutscenes/PartnerArchangelReaction_CountInc.tscn")
	partner_archangel_reaction_counter.take_over_path("res://cutscenes/archangels/PartnerArchangelReaction_CountInc.tscn")

	# Extend MissMimicSpawn_ChestInteract
	miss_mimic_spawn_chest_interact = load("res://mods/cat_sunny/cutscenes/MissMimicSpawn_ChestInteract.tscn")
	miss_mimic_spawn_chest_interact.take_over_path("res://cutscenes/passive_quests/MissMimicSpawn_ChestInteract.tscn")

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
	if index._parts_by_name.empty():
		return
	var pn: String = index.get_part_name(part)
	index._parts_by_name[pn] = part
	index.part_names.push_back(pn)


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
