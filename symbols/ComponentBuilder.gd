extends "res://modloader/utils.gd"
const cmgr = preload("res://effects-builder-plugin/symbols/ConditionManager.gd")
const tbldr = preload("res://effects-builder-plugin/symbols/TargetBuilder.gd")


class EffectComponent:
	var modsymbol
	var type : String
	var group : String
	var target_group
	var targets : int
	var random_targeting := true
	var animation : String
	var sfx_index : int = 0
	var simultaneous := false
	var random_index := -1
	var consumes_self := false
	var conditions := [] # of conditions
	
	
	func _init(modsymbol):
		self.modsymbol = modsymbol
		self.target_group = tbldr.parse(modsymbol, {"adjacent": {"not" : false}})
	
	
	func set_type(type : String):
		self.type = type
		return self
	
	
	func set_group(group : String):
		self.group = group
		return self
	
	
	func set_target(target_dict : Dictionary, number_of := 0, random := true):
		self.target_group = tbldr.parse(modsymbol, target_dict)
		if number_of > 0:
			self.targets = number_of
		self.random_targeting = random
		return self
	
	
	func simultaneous():
		self.simultaneous = true
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
		var condition = cmgr.parse(modsymbol, dict)
		if condition:
			self.conditions.push_back(condition)
		else:
			printerr("EBP ERROR: Condition could not be created from parameters")
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
				if condition.target in ["self", "any"]:
					if not condition.check_condition(symbol, effect):
						return
		
		for i in symbols:
			var i_effect = modsymbol.effect(effect.effect_dictionary.duplicate(true))
			if conditions:
				var check_passed := true
				for condition in conditions:
					if condition.target == "other":
						if not condition.check_condition(symbol, i_effect, i):
							check_passed = false
				if !check_passed:
					continue
			
			if consumes_self or simultaneous:
				if animation and not i in ani_arr:
					if not group and not type:
						ani_arr.push_back(i)
					elif i.type == type:
						ani_arr.push_back(i)
					elif group in i.groups:
						ani_arr.push_back(i)
			else:
				if animation:
					i_effect = i_effect.animate(animation, sfx_index, modsymbol.merge([symbol], [i]))
			
			symbol.add_effect_for_symbol(i, i_effect)
		
		if (consumes_self or simultaneous) and ani_arr.size() > 0:
			var l_effect = modsymbol.effect()
			if animation:
				l_effect = l_effect.animate(animation, sfx_index, modsymbol.merge([symbol], ani_arr))
			if consumes_self:
				l_effect = l_effect.set_destroyed()
			symbol.add_effect_for_symbol(symbol, l_effect)
	
	
	func get_description():
		var desc := ""
		if random_index >= 0:
			desc = "Has a <color_E14A68>%s%%<end> chance to"%modsymbol.values[random_index]
		return desc
	
	
	func get_targets(symbol, adjacent):
		var symbols : Array = target_group.build(symbol, adjacent)
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
				if condition.target in ["self", "any"]:
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
		elif group:
			effect = effect.if_group(group)
		
		if new_type:
			effect = effect.change_type(new_type)
		else:
			effect = effect.change_group(new_group, min_rarity)
		
		var t : Array = get_targets(symbol, adjacent)
		var symbols := []
		for i in t:
			if i.type == "empty" and !include_empties and type != "empty":
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
		var target_texts : String = target_group.get_description()
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
	var value := 0.0
	var not_prev := true
	var symbol_value := false
	var final_value := true
	
	
	func _init(modsymbol).(modsymbol):
		pass
	
	
	func set_buff(buff_type : String, value : float, symbol_value := false, final_value := true):
		if buff_type in ["temporary_bonus", "temporary_multiplier", "permanent_bonus", "permanent_multiplier"]:
			self.buff_type = buff_type
		if value >= 0:
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
				var i_effect = modsymbol.effect(b_effect.effect_dictionary.duplicate(true))
				if not type and not group:
					i_effect = i_effect.if_type(i.type)
				if symbol_value:
					i_effect.effect_dictionary.erase("diff")
					i_effect = i_effect.dynamic_symbol_value(i, value, final_value)
				symbol.add_effect_for_symbol(i, i_effect)
	
	
	func get_description():
		var desc : String = .get_description()
		if random_index >= 0:
			desc = modsymbol.join(desc, "<color_E14A68>destroy<end>")
		else:
			desc = "<color_E14A68>Destroys<end>"
		var target_texts : String = target_group.get_description()
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
	var value := 1.0
	var include_empties := false
	var symbol_value := false
	var final_value := false
	
	
	func _init(modsymbol).(modsymbol):
		pass
	
	
	func set_buff_type(buff_type : String):
		if buff_type in ["temporary_bonus", "temporary_multiplier", "permanent_bonus", "permanent_multiplier", "draining"]:
			self.buff_type = buff_type
		return self
	
	
	func set_value(value : float):
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
			if i.type == "empty" and !include_empties and type != "empty":
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
				if condition.target in ["self", "any"]:
					if not condition.check_condition(symbol, effect):
						return
		
		for i in symbols:
			var i_effect = modsymbol.effect(effect.effect_dictionary.duplicate(true))
			if conditions:
				var check_passed := true
				for condition in conditions:
					if condition.target == "other":
						if not condition.check_condition(symbol, i_effect, i):
							check_passed = false
				if !check_passed:
					continue
			
			if symbol_value:
				i_effect.effect_dictionary.erase("diff")
				i_effect = i_effect.dynamic_symbol_value(i, value, final_value)
			
			if not type and not group:
				i_effect = i_effect.if_type(i.type)
			
			if consumes_self or simultaneous:
				if animation and not i in ani_arr:
					if not type and not group:
						ani_arr.push_back(i)
					elif i.type == type:
						ani_arr.push_back(i)
					elif group in i.groups:
						ani_arr.push_back(i)
			else:
				if animation:
					i_effect = i_effect.animate(animation, sfx_index, modsymbol.merge([symbol], [i]))
			
			symbol.add_effect_for_symbol(i, i_effect)
			
		if (consumes_self or simultaneous) and ani_arr.size() > 0:
			var l_effect = modsymbol.effect()
			if animation:
				l_effect = l_effect.animate(animation, sfx_index, modsymbol.merge([symbol], ani_arr))
			if consumes_self:
				l_effect = l_effect.set_destroyed()
			symbol.add_effect_for_symbol(symbol, l_effect)
	
	func get_description():
		var desc : String = .get_description()
		if random_index >= 0:
			desc = modsymbol.join(desc, "grant")
		var target_texts : String = target_group.get_description()
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

