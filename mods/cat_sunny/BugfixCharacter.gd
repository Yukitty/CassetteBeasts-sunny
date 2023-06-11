extends Character


func battle_sprite_instance() -> Spatial:
	if battle_sprite:
		return battle_sprite.instance() as Spatial
	if is_human(character_kind):
		var result: Spatial = preload("res://nodes/layered_sprite/BattleHumanSprite3D.tscn").instance()
		result.set_colors(human_colors)
		result.set_part_names(human_part_names.duplicate()) # BUGFIX for Cassette Beasts v1.1.3
		return result
	return null
