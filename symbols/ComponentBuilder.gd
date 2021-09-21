extends "res://modloader/utils.gd"

class TargetBuilder:
	var modsymbol
	const valid_keys = [
		"adjacent", "row", "column", "all",
		"self", "corners", "edges", "above", "below",
		"left", "right", "diagonal"
	]
	const valid_operators = [true, false]
	const descriptions = {
		"adjacent" : {
			"text" : "adjacent ?",
			"nega" : "non-adjacent ?",
		},
		"row" : {
			"text" : "? in the same row",
			"nega" : "? not in the same row",
		},
		"column" : {
			"text" : "? in the same column",
			"nega" : "? not in the same column",
		},
		"all" : {
			"text" : "all ?",
			"nega" : "none of (wtf are you doing) ?",
		},
		"self" : {
			"text" : "",
			"nega" : "all other ?",
		},
		"corners" : {
			"text" : "? in a corner",
			"nega" : "? not in a corner",
		},
		"edges" : {
			"text" : "? on an edge",
			"nega" : "? not on an edge",
		},
		"above" : {
			"text" : "? above this symbol",
			"nega" : "? not above this symbol",
		},
		"below" : {
			"text" : "? below this symbol",
			"nega" : "? not below this symbol",
		},
		"left" : {
			"text" : "? to the left of this symbol",
			"nega" : "? not to the left of this symbol",
		},
		"right" : {
			"text" : "? to the right of this symbol",
			"nega" : "? not to the right of this symbol",
		},
		"diagonal" : {
			"text" : "? diagonally from this symbol",
			"nega" : "? not diagonally from this symbol",
		}
	}
	var cleansed_targets: Dictionary
	var reels
	
	
	func _init(modsymbol):
		self.modsymbol = modsymbol
		reels = modsymbol.modloader.globals.reels
	
	
	func parse(target_dict : Dictionary):
		for key in target_dict.keys():
			if not key in valid_keys:
				push_error("Invalid key value '%s', expected one of %s"%[key, valid_keys])
				return
			if target_dict[key].has("not"):
				if not target_dict[key]["not"] in valid_operators:
					push_error("Invalid operator '%s', expected one of %s"%[target_dict[key]["not"], valid_operators])
					return
			else:
				target_dict[key]["not"] = false
		cleansed_targets = target_dict
	
	
	func build(symbol, adjacent):
		var symbols := []
		for key in cleansed_targets.keys():
			var inner := []
			match key:
				"adjacent":
					inner = adjacent
				"row":
					inner = get_row(symbol, cleansed_targets[key]["include_self"])
				"column":
					inner = get_column(symbol, cleansed_targets[key]["include_self"])
				"all":
					inner = get_all(symbol, cleansed_targets[key]["include_self"])
				"self":
					inner.push_back(symbol)
				"corners":
					inner = get_corners()
				"edges":
					inner = get_edges()
				"above":
					inner = get_above(symbol)
				"below":
					inner = get_below(symbol)
				"left":
					inner = get_left(symbol)
				"right":
					inner = get_right(symbol)
				"diagonal":
					inner = get_diagonals(symbol)
			if cleansed_targets[key]["not"] == true:
				inner = modsymbol.subtract(get_all(symbol, true), inner)
			symbols = modsymbol.merge(symbols, inner)
		return symbols
	
	
	func get_row(symbol, include_self = false) -> Array:
		var symbols := []
		for x in range(reels.reel_width):
			if x == symbol.grid_position.x and !include_self:
				continue
			symbols.push_back(reels.displayed_icons[symbol.grid_position.y][x])
		return symbols
	
	
	func get_column(symbol, include_self = false) -> Array:
		var symbols := []
		for y in range(reels.reel_height):
			if y == symbol.grid_position.y and !include_self:
				continue
			symbols.push_back(reels.displayed_icons[y][symbol.grid_position.x])
		return symbols
	
	
	func get_left(symbol) -> Array:
		var symbols := []
		for x in range(reels.reel_width):
			if x > symbol.grid_position.x:
				continue
			symbols.push_back(reels.displayed_icons[symbol.grid_position.y][x])
		return symbols
	
	
	func get_right(symbol) -> Array:
		var symbols := []
		for x in range(reels.reel_width):
			if x < symbol.grid_position.x:
				continue
			symbols.push_back(reels.displayed_icons[symbol.grid_position.y][x])
		return symbols
	
	
	func get_above(symbol) -> Array:
		var symbols := []
		for y in range(reels.reel_height):
			if y > symbol.grid_position.y:
				continue
			symbols.push_back(reels.displayed_icons[y][symbol.grid_position.x])
		return symbols
	
	
	func get_below(symbol) -> Array:
		var symbols := []
		for y in range(reels.reel_height):
			if y < symbol.grid_position.y:
				continue
			symbols.push_back(reels.displayed_icons[y][symbol.grid_position.x])
		return symbols
	
	
	func get_diagonals(symbol):
		var symbols = []
		for direction in [1,2,3,4]:
			var x_mod = 0
			var y_mod = 0
			var x_diff = 0
			var y_diff = 0
			match int(direction):
				1:
					x_diff = -1
					y_diff = -1
				2:
					x_diff = 1
					y_diff = -1
				3:
					x_diff = -1
					y_diff = 1
				4:
					x_diff = 1
					y_diff = 1
			x_mod += x_diff
			y_mod += y_diff
			while symbol.grid_position.x + x_mod >= 0 and symbol.grid_position.y + y_mod >= 0 and symbol.grid_position.x + x_mod <= reels.reel_width - 1 and symbol.grid_position.y + y_mod <= reels.reel_height - 1:
				symbols.push_back(reels.displayed_icons[symbol.grid_position.y + y_mod][symbol.grid_position.x + x_mod])
				x_mod += x_diff
				y_mod += y_diff
		return symbols
	
	
	func get_all(symbol, include_self = false) -> Array:
		var symbols := []
		for row in reels.displayed_icons:
			symbols += row
		if !include_self:
			symbols.erase(symbol)
		return symbols
	
	
	func get_corners() -> Array:
		var symbols := []
		symbols.push_back(reels.displayed_icons[0][0])
		symbols.push_back(reels.displayed_icons[0][reels.reel_width -1])
		symbols.push_back(reels.displayed_icons[reels.reel_height - 1][0])
		symbols.push_back(reels.displayed_icons[reels.reel_height - 1][reels.reel_width - 1])
		return symbols
	
	
	func get_edges() -> Array:
		var symbols := []
		for row in reels.displayed_icons:
			for s in row:
				if s.grid_position.y == 0 \
				or s.grid_position.x == 0 \
				or s.grid_position.y == reels.reel_height - 1 \
				or s.grid_position.x == reels.reel_width -1:
					symbols.push_back(s)
		return symbols
	
	
	func get_description():
		var desc := ""
		for key in cleansed_targets.keys():
			var inner : String = descriptions[key]["text"] if cleansed_targets[key]["not"] == false else descriptions[key]["nega"]
			if !desc:
				desc = inner
			else:
				desc += " or " + inner.replace("? ", "")
		return desc


class EffectComponent:
	var modsymbol
	var type : String
	var group : String
	var target : TargetBuilder
	var targets : int
	var random_targeting := true
	var animation : String
	var sfx_index : int = 0
	var random_index := -1
	var consumes_self := false
	var conditions := [] # of conditions
	
	
	func _init(modsymbol):
		self.modsymbol = modsymbol
		self.target = TargetBuilder.new(modsymbol)
		self.target.parse({"adjacent": {"not" : false}})
	
	
	func set_type(type : String):
		self.type = type
		return self
	
	
	func set_group(group : String):
		self.group = group
		return self
	
	
	func set_target(target_dict : Dictionary, number_of := 0, random := true):
		self.target.parse(target_dict)
		if number_of > 0:
			self.targets = number_of
		self.random_targeting = random
		return self
	
	
	func random(index : int):
		if 100 >= modsymbol.values[index] and modsymbol.values[index] > 0:
			self.random_index = index
		return self
	
	
	func animate(animation : String, sfx_index := 0):
		self.animation = animation
		self.sfx_index = sfx_index
		return self
	
	
	func consumes():
		self.consumes_self = true
		return self
	
	
	func add_condition(dict : Dictionary):
		var condition = Condition.new(modsymbol)
		condition.parse(dict)
		self.conditions.push_back(condition)
		return self
	
	
	func construct(effect, symbol, symbols):
		if !symbols:
			printerr("EBP ERROR: No valid targets")
			return
		
		var ani_arr = []
		
		if random_index >= 0:
			effect = effect.if_value_random(random_index)
		
		if conditions:
			for condition in conditions:
				if condition.target == "self":
					if not condition.check_condition(symbol, effect):
						return
		
		for i in symbols:
			var i_effect = modsymbol.effect(effect.effect_dictionary.duplicate())
			if conditions:
				var check_passed := true
				for condition in conditions:
					if condition.target == "other":
						if not condition.check_condition(i, i_effect):
							check_passed = false
				if !check_passed:
					continue
			if consumes_self:
				if animation and not i in ani_arr:
					if not group and not type:
						ani_arr.push_back(i)
					elif i.type == type:
						ani_arr.push_back(i)
					elif group in i.groups:
						ani_arr.push_back(i)
				symbol.add_effect_for_symbol(i, i_effect)
			else:
				if animation:
					i_effect = i_effect.animate(animation, sfx_index, modsymbol.merge([symbol], [i]))
				symbol.add_effect_for_symbol(i, i_effect)
		if consumes_self and ani_arr.size() > 0:
			var l_effect = modsymbol.effect()
			if animation:
				l_effect = l_effect.animate(animation, sfx_index, modsymbol.merge([symbol], ani_arr))
			l_effect = l_effect.set_destroyed()
			symbol.add_effect_for_symbol(symbol, l_effect)
	
	
	func get_description():
		var desc := ""
		if random_index >= 0:
			desc = "Has a <color_E14A68>%s%%<end> chance to"%modsymbol.values[random_index]
		return desc
	
	
	func get_targets(symbol, adjacent):
		var symbols : Array = target.build(symbol, adjacent)
		return symbols


class Spawnable extends EffectComponent:
	var quantity := 1
	var new_type : String
	var new_group : String
	var min_rarity := ""
	
	
	func _init(modsymbol).(modsymbol):
		pass
	
	
	func set_quantity(quantity : int):
		self.quantity = quantity if quantity > 0 else 1
		return self
	
	
	func set_new_type(new_type : String):
		self.new_type = new_type
		return self
	
	
	func set_new_group(new_group : String, min_rarity := ""):
		if min_rarity in ["uncommon", "rare", "very_rare"]:
			self.min_rarity = min_rarity
		self.new_group = new_group
		return self
	
	
	func spawn_multiple(symbol_type_or_group: String, amount := 0):
		var spawn := []
		for i in amount:
			spawn.push_back(symbol_type_or_group)
		return spawn
	
	
	func construct(effect, symbol, adjacent):
		if not new_type and not new_group:
			printerr("EBP ERROR: Spawning requires either a symbol type or group, skipping...")
			return effect
		
		if random_index >= 0:
			effect = effect.if_value_random(random_index)
		
		if new_type:
			effect = effect.add_symbols_of_type(spawn_multiple(new_type, quantity))
		else:
			effect = effect.add_symbols_of_group(spawn_multiple(new_group, quantity), min_rarity)
		
		if animation:
			effect = effect.animate(animation, sfx_index)
		
		if conditions:
			for condition in conditions:
				if condition.target == "self":
					if not condition.check_condition(symbol, effect):
						return
		
		symbol.add_effect(effect)
	
	
	func get_description():
		var desc : String = .get_description()
		if random_index >= 0:
			desc = modsymbol.join(desc, "<color_E14A68>add")
		else:
			desc = "<color_E14A68>Adds"
		if quantity > 1:
			desc = modsymbol.join(desc, str(quantity))
		desc = modsymbol.join(desc, "<end>", "")
		if new_type:
			desc = modsymbol.join(desc, "<icon_%s>"%new_type)
		else:
			desc = modsymbol.join(desc, "<all_or_%s>"%new_group)
		if conditions:
			for condition in conditions:
				desc = modsymbol.join(desc, condition.get_description())
		else:
			if !(random_index >= 0):
				desc = modsymbol.join(desc, "each spin")
		desc += "."
		if consumes_self:
			desc = modsymbol.join(desc, "<color_E14A68>Destroys<end> itself afterwards.")
		return desc.substr(0,1).to_upper() + desc.substr(1)


class Transformable extends EffectComponent:
	var include_empties := false
	var new_type : String
	var new_group : String
	var min_rarity := ""
	
	
	func _init(modsymbol).(modsymbol):
		pass
	
	
	func empties():
		self.include_empties = true
	
	
	func set_new_type(new_type : String):
		self.new_type = new_type
		return self
	
	
	func set_new_group(new_group : String, min_rarity := ""):
		if min_rarity in ["uncommon", "rare", "very_rare"]:
			self.min_rarity = min_rarity
		self.new_group = new_group
		return self
	
	
	func construct(effect, symbol, adjacent):
		if not new_type and not new_group:
			printerr("EBP ERROR: Transforms requires either a symbol type or group, skipping...")
			return
		
		if type:
			effect = effect.if_type(type)
		else:
			effect = effect.if_group(group)	
		
		if new_type:
			effect = effect.change_type(new_type)
		else:
			effect = effect.change_group(new_group, min_rarity)
		
		var t : Array = get_targets(symbol, adjacent)
		var symbols := []
		for i in t:
			if i.type == "empty" and !include_empties:
				continue
			if i.type != new_type:
				symbols.push_back(i)
		
		.construct(effect, symbol, symbols)
	
	
	func get_description():
		var desc : String = .get_description()
		if random_index >= 0:
			desc = modsymbol.join(desc, "transform")
		else:
			desc = "transforms"
		var target_texts : String = target.get_description()
		if type:
			target_texts = target_texts.replace("?", "<icon_%s>"%type)
		elif group:
			target_texts = target_texts.replace("?", "<all_and_%s>"%group)
		else:
			target_texts = target_texts.replace("?", "symbols")
		desc = modsymbol.join(desc, target_texts)
		desc += " into"
		if new_type:
			desc = modsymbol.join(desc, "<icon_%s>"%new_type)
		else:
			desc = modsymbol.join(desc, "<all_or_%s>"%new_group)
		if conditions:
			var conditions_text := ""
			for condition in conditions:
				if !conditions_text:
					conditions_text = condition.get_description()
				else:
					conditions_text += " and " + condition.get_description()
			desc = modsymbol.join(desc, conditions_text)
		desc += "."
		if consumes_self:
			desc = modsymbol.join(desc, "<color_E14A68>Destroys<end> itself afterwards.")
		return desc.substr(0,1).to_upper() + desc.substr(1)


class Destroyer extends EffectComponent:
	var buff_type := "temporary_bonus"
	var value := 0
	var not_prev := true
	var symbol_value := false
	var final_value := true
	
	
	func _init(modsymbol).(modsymbol):
		pass
	
	
	func set_buff(buff_type : String, value : int, symbol_value := false, final_value := true):
		if buff_type in ["temporary_bonus", "temporary_multiplier", "permanent_bonus", "permanent_multiplier"]:
			self.buff_type = buff_type
		if value >= 1:
			self.value = value
		self.symbol_value = symbol_value
		self.final_value = final_value
		return self
	
	
	func construct(effect, symbol, adjacent):
		effect.set_destroyed()
		
		if type:
			effect = effect.if_type(type, not_prev)
		elif group:
			effect = effect.if_group(group, not_prev)
		
		var symbols : Array = get_targets(symbol, adjacent)
		
		.construct(effect, symbol, symbols)
		
		if buff_type:
			var b_effect = modsymbol.effect().if_destroyed().set_target(symbol)
			
			if type:
				b_effect = b_effect.if_type(type)
			elif group:
				b_effect = b_effect.if_group(group)
			
			match buff_type:
				"temporary_bonus":
					b_effect = b_effect.change_value_bonus(value)
				"temporary_multiplier":
					b_effect = b_effect.change_value_multiplier(value)
				"permanent_bonus":
					b_effect = b_effect.add_permanent_bonus(value)
				"permanent_multiplier":
					b_effect = b_effect.multiply_permanent_multiplier(value)
			
			for i in symbols:
				var i_effect = modsymbol.effect(b_effect.effect_dictionary.duplicate())
				if symbol_value:
					i_effect.effect_dictionary.erase("diff")
					i_effect = i_effect.dynamic_symbol_value(i, value, final_value)
					print(i_effect.effect_dictionary)
				symbol.add_effect_for_symbol(i, i_effect)
	
	
	func get_description():
		var desc : String = .get_description()
		if random_index >= 0:
			desc = modsymbol.join(desc, "<color_E14A68>destroy<end>")
		else:
			desc = "<color_E14A68>Destroys<end>"
		var target_texts : String = target.get_description()
		if type:
			target_texts = target_texts.replace("?", "<icon_%s>"%type)
		elif group:
			target_texts = target_texts.replace("?", "<all_and_%s>"%group)
		else:
			target_texts = target_texts.replace("?", "symbols")
		if target_texts == "":
			target_texts = "itself"
		desc = modsymbol.join(desc, target_texts)
		if conditions:
			var conditions_text := ""
			for condition in conditions:
				if !conditions_text:
					conditions_text = condition.get_description()
				else:
					conditions_text += " and " + condition.get_description()
			desc = modsymbol.join(desc, conditions_text)
		desc += "."
		if value:
			if buff_type in ["permanent_bonus", "permanent_multiplier"]:
				desc = modsymbol.join(desc, "Permanently gives")
			else:
				desc = modsymbol.join(desc, "Gives")
			if symbol_value:
				if buff_type in ["temporary_bonus", "permanent_bonus"]:
					desc = modsymbol.join(desc, "<icon_coin> equal to%s the%s value of symbols <color_E14A68>destroyed<end> this way."%[" <color_E14A68>%sx<end>"%value if value and value > 1 else "", " base" if !final_value else ""])
				else:
					desc = modsymbol.join(desc, "more <icon_coin> equal to%s the%s value of symbols <color_E14A68>destroyed<end> this way."%[" <color_E14A68>%sx<end>"%value if value and value > 1 else "", " base" if !final_value else ""])
			else:
				if buff_type in ["temporary_bonus", "permanent_bonus"]:
					desc = modsymbol.join(desc, "<icon_coin><color_FBF236>%s<end> more"%value)
				else:
					desc = modsymbol.join(desc, "<color_E14A68>%sx<end> more <icon_coin>"%value)
				var s = "<icon_%s>"%type if type else "symbol"
				desc = modsymbol.join(desc, "for each %s <color_E14A68>destroyed<end>."%s)
		if consumes_self:
			desc = modsymbol.join(desc, "<color_E14A68>Destroys<end> itself afterwards.")
		return desc.substr(0,1).to_upper() + desc.substr(1)


class Buff extends EffectComponent:
	var buff_type := "temporary_multiplier"
	var value := 1
	var include_empties := false
	var symbol_value := false
	var final_value := false
	
	
	func _init(modsymbol).(modsymbol):
		pass
	
	
	func set_buff_type(buff_type : String):
		if buff_type in ["temporary_bonus", "temporary_multiplier", "permanent_bonus", "permanent_multiplier", "draining"]:
			self.buff_type = buff_type
		return self
	
	
	func set_value(value : int):
		if value >= 0:
			self.value = value
		return self
	
	
	func symbol_value_diff():
		self.symbol_value = true
		return self
	
	func final():
		self.final_value = true
		return self
	
	
	func empties():
		self.include_empties = true
	
	
	func construct(effect, symbol, adjacent):
		match buff_type:
			"temporary_bonus":
				effect = effect.change_value_bonus(value)
			"temporary_multiplier":
				effect = effect.change_value_multiplier(value)
			"permanent_bonus":
				effect = effect.add_permanent_bonus(value)
			"permanent_multiplier":
				effect = effect.multiply_permanent_multiplier(value)
			"draining":
				effect = effect.set_drained()
		
		if type:
			effect = effect.if_type(type)
		elif group:
			effect = effect.if_group(group)
		
		var t : Array = get_targets(symbol, adjacent)
		var symbols := []
		for i in t:
			if i.type == "empty" and !include_empties:
				continue
			symbols.push_back(i)
		
		if !symbols:
			printerr("EBP ERROR: No valid targets")
			return
		
		var ani_arr = []
		
		if random_index >= 0:
			effect = effect.if_value_random(random_index)
		
		if conditions:
			for condition in conditions:
				if condition.target == "self":
					if not condition.check_condition(symbol, effect):
						return
		
		for i in symbols:
			var i_effect = modsymbol.effect(effect.effect_dictionary.duplicate())
			if conditions:
				var check_passed := true
				for condition in conditions:
					if condition.target == "other":
						if not condition.check_condition(i, i_effect):
							check_passed = false
				if !check_passed:
					continue
			if consumes_self:
				if animation and not i in ani_arr:
					if not group and not type:
						ani_arr.push_back(i)
					elif i.type == type:
						ani_arr.push_back(i)
					elif group in i.groups:
						ani_arr.push_back(i)
				symbol.add_effect_for_symbol(i, i_effect)
			else:
				if animation:
					i_effect = i_effect.animate(animation, sfx_index, modsymbol.merge([symbol], [i]))
				if symbol_value:
					i_effect.effect_dictionary.erase("diff")
					i_effect = i_effect.dynamic_symbol_value(i, value, final_value)
				symbol.add_effect_for_symbol(i, i_effect)
		if consumes_self and ani_arr.size() > 0:
			var l_effect = modsymbol.effect()
			if animation:
				l_effect = l_effect.animate(animation, sfx_index, modsymbol.merge([symbol], ani_arr))
			l_effect = l_effect.set_destroyed()
			symbol.add_effect_for_symbol(symbol, l_effect)
	
	func get_description():
		var desc : String = .get_description()
		if random_index >= 0:
			desc = modsymbol.join(desc, "grant")
		var target_texts : String = target.get_description()
		if type:
			target_texts = target_texts.replace("?", "<icon_%s>"%type)
		elif group:
			target_texts = target_texts.replace("?", "<all_and_%s>"%group)
		else:
			target_texts = target_texts.replace("?", "symbols")
		desc = modsymbol.join(desc, target_texts)
		if buff_type in ["permanent_bonus", "permanent_multiplier"]:
			desc = modsymbol.join(desc, "permanently")
		if target_texts == "":
			desc = modsymbol.join(desc, "gives")
		else:
			desc = modsymbol.join(desc, "give")
		if symbol_value:
			if buff_type in ["temporary_bonus", "permanent_bonus"]:
				desc = modsymbol.join(desc, "<icon_coin> equal to%s their%s value"%[" <color_E14A68>%sx<end>"%value if value and value > 1 else "", " base" if !final_value else ""])
			else:
				desc = modsymbol.join(desc, "more <icon_coin> equal to%s their%s value"%[" <color_E14A68>%sx<end>"%value if value and value > 1 else "", " base" if !final_value else ""])
		else:
			if buff_type == "draining":
				desc = modsymbol.join(desc, "<icon_coin><color_FBF236>0<end>")
			elif buff_type in ["temporary_bonus", "permanent_bonus"]:
				desc = modsymbol.join(desc, "<icon_coin><color_FBF236>%s<end> more"%value)
			else:
				desc = modsymbol.join(desc, "<color_E14A68>%sx<end> more <icon_coin>"%value)
		if conditions:
			var conditions_text := ""
			for condition in conditions:
				if !conditions_text:
					conditions_text = condition.get_description()
				else:
					conditions_text += " and " + condition.get_description()
			desc = modsymbol.join(desc, conditions_text)
		desc += "."
		if consumes_self:
			desc = modsymbol.join(desc, "<color_E14A68>Destroys<end> itself afterwards.")
		return desc.substr(0,1).to_upper() + desc.substr(1)


class Condition:
	const target_types := ["self", "other"]
	const valid_conditions := ["turns", "symbol_count", "symbol_value", "item", "corner", "edge", "destroyed", "adjacent"]
	const valid_operators := ["exactly", "at_least", "less_than", "every"]
	var reels
	var modsymbol
	var dict : Dictionary
	var target := "self"
	var value : int
	var invert := false
	
	
	func _init(modsymbol):
		self.modsymbol = modsymbol
		reels = modsymbol.modloader.globals.reels
	
	
	func parse(dict : Dictionary):
		if dict.has("target"):
			if not dict["target"] in target_types:
				printerr("EBP ERROR: Given target '%s' is not one of the accepted targets: %s"%[dict["target"], target_types])
				return
			else:
				self.target = dict["target"]
		
		if not dict.has("condition"):
			printerr("EBP ERROR: Requires a condition to be given, skipping...")
			return
		elif not dict["condition"] in valid_conditions:
			printerr("EBP ERROR: Given condition '%s' is not one of the accepted conditions: %s"%[dict["condition"], valid_conditions])
			return
		else:
			match dict["condition"]:
				"turns", "symbol_count", "symbol_value":
					if !dict.has("operator"):
						printerr("EBP ERROR: An operator must be given for the given condition, skipping...")
					elif not dict["operator"] in valid_operators:
						printerr("EBP ERROR: Given operator '%s' is not one of the accepted conditions: %s"%[dict["operator"], valid_operators])
						return
					if dict["condition"] == "symbol_count" and not dict.has("type") and not dict.has("group"):
						printerr("EBP ERROR: A type or group must be given for condition 'symbol_count'")
						return
				"item":
					if !dict.has("type"):
						printerr("EBP ERROR: An item type must be given for condition 'item'")
						return
				"adjacent":
					if !dict.has("type") and !dict.has("group"):
						printerr("EBP ERROR: A type or group must be given for condition 'adjacent'")
						return
		
		if dict.has("value"):
			self.value = dict["value"]
		
		if dict.has("not"):
			self.invert = dict["not"]
		
		self.dict = dict
	
	
	func check_condition(symbol, effect):
		var result := false
		match dict["condition"]:
			"turns":
				match dict["operator"]:
					"exactly":
						effect = effect.if_property_equals("times_displayed", value)
					"at_least":
						effect = effect.if_property_at_least("times_displayed", value)
					"less_than":
						effect = effect.if_property_less_than("times_displayed", value)
					"every":
						symbol.add_effect(modsymbol.effect().if_property_at_least("times_displayed", value).set_value("times_displayed", 0))
						effect = effect.if_property_at_least("times_displayed", value).priority()
				return true
			
			"symbol_count":
				var symbol_count
				var source := "reels"
				if dict.has("source"):
					if dict["source"] in ["reels", "inventory"]:
						source = dict["source"]
				if dict.has("type"):
					symbol_count = modsymbol.count_symbols(source, {"type": dict["type"]})
				elif dict.has("group"):
					symbol_count = modsymbol.count_symbols(source, {"group": dict["group"]})
				else:
					symbol_count = modsymbol.count_symbols(source)
				if dict["operator"] == "every":
					if not dict.has("type") and not dict.has("group"):
						return false
					else:
						result = apply_operator("exactly", symbol_count, modsymbol.count_symbols(source))
				result = apply_operator(dict["operator"], symbol_count, value)
			
			"symbol_value":
				var compare := "value"
				if dict.has("value_type"):
					compare = dict["value_type"] if dict["value_type"] in ["value", "final_value", "value_bonus"] else "value"
				
				match dict["operator"]:
					"exactly":
						effect = effect.if_property_equals(compare, value)
					"at_least":
						effect = effect.if_property_at_least(compare, value)
					"less_than":
						effect = effect.if_property_less_than(compare, value)
					_:
						return false
				return true
			
			"corner":
				var top_left = symbol.grid_position.x == 0 and symbol.grid_position.y == 0
				var top_right = symbol.grid_position.x == reels.reel_width - 1 and symbol.grid_position.y == 0
				var bottom_left = symbol.grid_position.x == 0 and symbol.grid_position.y == reels.reel_height - 1
				var bottom_right = symbol.grid_position.x == reels.reel_width - 1 and symbol.grid_position.y == reels.reel_height - 1
				if not (top_left or top_right or bottom_left or bottom_right):
					result = true
			
			"edge":
				var left = symbol.grid_position.x == 0 
				var right = symbol.grid_position.x == reels.reel_width - 1
				var top = symbol.grid_position.y == 0
				var bottom = symbol.grid_position.y == reels.reel_height - 1
				if (left or right or top or bottom):
					result = true
			
			"destroyed":
				effect = effect.if_destroyed(!invert).if_type(symbol.type).priority()
				return true
			
			"item":
				if modsymbol.modloader.globals.items.item_types.has(dict["type"]):
					result = true
			
			"adjacent":
				var operator := "at_least"
				var finalvalue := value if value else 1
				var count := 0
				if dict.has("operator"):
					operator = dict["operator"]
				var adjacents : Array = symbol.get_adjacent_icons()
				if operator == "every":
					finalvalue = adjacents.size()
					operator = "at_least"
				for adjacent in adjacents:
					if adjacent.type == dict["type"] or dict["group"] in adjacent.groups:
						count += 1
				result = apply_operator(operator, count, finalvalue)
			
			_:
				return false
			
		if invert:
			result = !result
		return result
	
	
	func apply_operator(operator, value, compare):
		match operator:
			"exactly":
				return value == compare
			"at_least":
				return value >= compare
			"less_than":
				return value < compare
		return false
	
	
	func get_type_or_group(stringsafe := true, andor := "na"):
		var result := ""
		if dict.has("type"):
			result = dict["type"]
			if stringsafe:
				result = "<icon_%s>"%result
		elif dict.has("group"):
			if not andor in ["and", "or", "na"]:
				andor = "na"
			result = dict["group"]
			if stringsafe:
				result = "<all_%s_%s>"%[andor, result]
		return result
	
	
	func get_description():
		var a : String
		var b : String
		var c : String
		var d : String
		var e : String
		match dict["condition"]:
			"turns":
				match dict["operator"]:
					"exactly":
						return "nyi"
					"at_least":
						return "after <color_E14A68>%s<end> spins"%value
					"less_than":
						return "nyi"
					"every":
						return "every <color_E14A68>%s<end> spins"%value
			
			"symbol_count":
				a = "is" if value == 1 else "are"
				b = dict["operator"].replace("_", " ")
				c = get_type_or_group(true, "or")
				d = " in your inventory" if dict.has("source") and dict["source"] == "inventory" else ""
				return "if there %s %s <color_E14A68>%s<end> %s%s"%[a, b, value, c, d]
			
			"symbol_value":
				a = "its" if dict.has("target") and dict["target"] == "other" else "this symbol's"
				b = dict["operator"].replace("_", " ")
				c = ""
				if dict.has("value_type"):
					match dict["value_type"]:
						"final_value":
							c = "value"
						"value_bonus":
							c = "bonus value"
						_:
							"base value"
				return "if %s %s is %s %s"%[a, c, b, value]
			
			"corner":
				a = "this symbol" if dict["target"] == "self" else "it"
				b = " <color_E14A68>not<end>" if invert else ""
				return "if %s is%s in a corner"%[a, b]
			
			"edge":
				a = "this symbol" if dict["target"] == "self" else "it"
				b = " <color_E14A68>not<end>" if invert else ""
				return "if %s is%s on an edge"%[a, b]
			
			"destroyed":
				return "when <color_E14A68>destroyed<end>"
			
			"item":
				a = " do <color_E14A68>not<end>" if invert else ""
				b = dict["type"]
				return "if you%s have <icon_%s>"%[a, b]
			
			"adjacent":
				a = " <color_E14A68>not<end>" if invert else ""
				c = get_type_or_group(true, "or")
				if dict.has("operator"):
					match dict["operator"]:
						"at_least":
							b = "at least <color_E14A68>%s<end>"%value if value else "0"
							return "if%s adjacent to %s%s"%[a, b, c]
						"less_than":
							b = "fewer than <color_E14A68>%s<end>"%value if value else "0"
							return "if%s adjacent to %s%s"%[a, b, c]
						"exactly":
							b = value if value else "1"
							return "if%s adjacent to exactly <color_E14A68>%s<end>%s"%[a, b, c]
						"every":
							return "if%s surrounded by %s"%[a, c]
				return "if%s adjacent to %s"%[a, c]
