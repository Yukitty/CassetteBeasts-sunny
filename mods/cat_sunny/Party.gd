extends "res://global/save_state/Party.gd"


func start_new_file() -> void:
	.start_new_file()
	_assign_bonus_stickers()


func remap_partner_tapes() -> void:
	for partner in partners:
		if is_partner_unlocked(partner.partner_id):
			continue

		# BUGFIX: Set partner levels for new custom partners
		if initial_partner_levels.has(partner.partner_id):
			partner.level = initial_partner_levels[partner.partner_id]

		assert (partner.tapes.size() == 1)
		if partner.tapes.size() != 1:
			continue
		var tape = partner.tapes[0]
		if tape.form == partner.partner_signature_species:
			tape.form = MonsterForms.get_species_mapping(tape.form)

			# BUGFIX: Only clear bootleg in type randomizer runs
			if MonsterForms.type_rand_seed != null:
				tape.type_override = []

			tape.type_native = MonsterForms.get_type_mapping(tape.form)
			tape.assign_initial_stickers(true)
	_assign_bonus_stickers()


func _assign_bonus_stickers() -> void:
	# This applies bonus stickers
	# specified in BonusStickersCharacter partners
	# This is a dumb mod hack to work around tape.assign_initial_stickers
	for partner in partners:
		if not "bonus_stickers" in partner:
			continue
		if is_partner_unlocked(partner.partner_id):
			continue
		assert(partner.tapes.size() == 1)
		if partner.tapes.size() != 1:
			continue
		var tape: MonsterTape = partner.tapes[0]
		for move in partner.bonus_stickers:
			var compat_move: BattleMove = BattleMoves.replace_with_compatible(tape, move, false)
			var rarity: int = tape.rand_sticker_rarity(true, null)
			tape.stickers.push_back(ItemFactory.create_sticker(compat_move, null, rarity))
