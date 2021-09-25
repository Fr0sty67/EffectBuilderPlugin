const valid_targets := ["self", "other", "any"]
const valid_conditions := ["turns", "symbol_count", "symbol_value", "item", "corner", "edge", "destroyed", "adjacent"]
const valid_operators := ["exactly", "at_least", "less_than", "every"]
const valid_source := ["inventory", "reels"]


static func parse(modsymbol, dict : Dictionary) -> Condition:
	var condition
	if dict.has("target") and not dict["target"] in valid_targets:
		printerr("EBP ERROR: Given target '%s' is not one of the accepted targets: %s"%[dict["target"], valid_targets])
		return Condition.new(modsymbol)
	
	if dict.has("operator") and not dict["operator"] in valid_operators:
		printerr("EBP ERROR: Given operator '%s' is not one of the accepted operators: %s"%[dict["operator"], valid_operators])
		return Condition.new(modsymbol)
	
	if not dict.has("condition"):
		printerr("EBP ERROR: Requires a 'condition' to be given")
		return Condition.new(modsymbol)
	else:
		match dict["condition"]:
#			"adjacent":
#				condition = AdjacentCondition.new(modsymbol, dict)
			"destroyed":
				condition = DestroyedCondition.new(modsymbol, dict)
			"item":
				condition = HaveItemCondition.new(modsymbol, dict)
			"symbol_count":
				condition = SymbolCountCondition.new(modsymbol, dict)
			"symbol_value":
				condition = SymbolValueCondition.new(modsymbol, dict)
			"turns":
				condition = TurnCountCondition.new(modsymbol, dict)
			"adjacent", "row", "column", "corner", "edge", "above", "below", "left", "right", "diagonal":
				condition = PositionCondition.new(modsymbol, dict)
	if not condition or not condition.valid:
		printerr("EBP ERROR: Invalid condition %s"%dict["condition"])
		return Condition.new(modsymbol)
	
	if dict.has("value"):
		condition.value = dict["value"]
	if dict.has("not"):
		condition.invert = dict["not"]
	if dict.has("operator"):
		condition.operator = dict["operator"]
	if dict.has("target"):
		condition.target = dict["target"]
	
	return condition


class Condition:
	var reels
	var modsymbol
	var target := "self"
	var value : float
	var invert := false
	var operator : String
	var valid := false
	var tb
	
	
	func _init(modsymbol):
		self.modsymbol = modsymbol
		reels = modsymbol.modloader.globals.reels
		tb = modsymbol.cbldr.tbldr
	
	
	func check_condition(symbol, effect, i = null):
		printerr("EBP ERROR: Function 'check_condition' must be called from the child class")
		return false
	
	
	func apply_operator(operator, value, compare) -> bool:
		match operator:
			"exactly":
				return value == compare
			"at_least":
				return value >= compare
			"less_than":
				return value < compare
		return false
	
	
	func get_type_or_group(condition, stringsafe := true, andor := "na"):
		var result := ""
		if condition.type:
			result = condition.type
			if stringsafe:
				result = "<icon_%s>"%result
		elif condition.group:
			if not andor in ["and", "or", "na"]:
				andor = "na"
			result = condition.group
			if stringsafe:
				result = "<all_%s_%s>"%[andor, result]
		return result
	
	
	func get_description():
		pass


class AdjacentCondition extends Condition:
	var type : String
	var group : String
	
	
	func _init(modsymbol, dict : Dictionary).(modsymbol):
		if dict.has("type"):
			self.type = dict["type"]
		if dict.has("group"):
			self.group = dict["group"]
		self.valid = true
	
	
	func check_condition(symbol, effect, i = null):
		var result := false
		var operator := "at_least"
		var finalvalue := value if value else 1.0
		var count := 0
		var adjacents : Array = symbol.get_adjacent_icons()
		if operator == "every":
			finalvalue = adjacents.size()
			operator = "at_least"
		for adjacent in adjacents:
			if adjacent.type == type or group in adjacent.groups:
				count += 1
		result = apply_operator(operator, count, finalvalue)
		return !result if invert else result
	
	
	func get_description():
		var a : String = " <color_E14A68>not<end>" if invert else ""
		var b : String
		var c : String = get_type_or_group(self, true, "or")
		if operator:
			match operator:
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


class DestroyedCondition extends Condition:
	func _init(modsymbol, dict : Dictionary).(modsymbol):
		self.valid = true
	
	
	func check_condition(symbol, effect, i = null):
		effect = effect.if_destroyed(!invert).if_type(symbol.type).priority()
		return true
	
	
	func get_description():
		return "when <color_E14A68>%sdestroyed<end>"%["not " if invert else ""]


class HaveItemCondition extends Condition:
	var item_type : String
	
	func _init(modsymbol, dict : Dictionary).(modsymbol):
		if !dict.has("type"):
			printerr("EBP ERROR: An item 'type' must be given for condition 'item'")
			return
		self.item_type = dict["type"]
		self.valid = true
	
	
	func check_condition(symbol, effect, i = null):
		var result := false
		if modsymbol.modloader.globals.items.item_types.has(item_type):
			result = true
		return !result if invert else result
	
	
	func get_description():
		var a : String = " do <color_E14A68>not<end>" if invert else ""
		var b : String = item_type
		return "if you%s have <icon_%s>"%[a, b]


class PositionCondition extends Condition:
	var type : String
	var group : String
	var position : String
	var index : int
	var relative := false
	var source := "reels"
	
	func _init(modsymbol, dict : Dictionary).(modsymbol):
		self.position = dict["condition"]
		
		if position in ["adjacent", "above", "below", "left", "right", "diagonal"]:
			if dict.has("target"):
				if dict["target"] == "self":
					printerr("EBP ERROR: self cannot be '%s' to self; target must be 'other' or 'any'"%position)
					return
			else:
				dict["target"] = "any"
		
		if dict.has("type"):
			self.type = dict["type"]
		
		if dict.has("group"):
			self.group = dict["group"]
		
		if dict.has("index"):
			if position == "row":
				self.index = int(dict["index"])
				if not index in range(reels.reel_height):
					printerr("EBP ERROR: Invalid index '%s', must be between 0 and %s"%[index, reels.reel_height-1])
					return
			elif position == "column":
				self.index = int(dict["index"])
				if not index in range(reels.reel_width):
					printerr("EBP ERROR: Invalid index '%s', must be between 0 and %s"%[index, reels.reel_width-1])
					return
		else:
			if position in ["row", "column"] and dict["target"] == "self":
				printerr("EBP ERROR: Row or column index not specified; condition will always return true")
				return
		
		if dict.has("relative"):
			if dict["relative"] in [true, false]:
				self.relative = dict["relative"]
		
		if relative:
			if dict["target"] in ["self", "any"]:
				printerr("EBP ERROR: %s cannot be relative"%dict["target"])
				return
			elif position in ["corner", "edge"]:
				printerr("EBP ERROR: %s cannot be relative"%position)
				return
			elif index >= 0:
				printerr("EBP WARNING: Index is discarded if an relative is true, continuing...")
				self.index = -1
		else:
			if dict["target"] == "other":
				if position in ["adjacent", "above", "below", "left", "right", "diagonal"]:
					printerr("EBP ERROR: 'other' cannot be absolute to '%s'"%position)
					return
		
		if dict["target"] == "any" or (dict["target"] == "other" and relative):
			if position in ["adjacent", "above", "below", "left", "right", "diagonal"]:
				if not dict.has("operator"):
					dict["operator"] = "at_least"
				if not dict.has("value"):
					dict["value"] = 1
		
		self.valid = true
	
	
	func check_condition(symbol, effect, i = null):
		var result := false
		var symbols : Array
		match target:
			"self":
				result = check_for_self(symbol, effect, symbols)
			"other":
				result = check_for_other(symbol, effect, i, symbols)
			"any":
				result = check_for_any(symbol, effect, symbols)
		return !result if invert else result
	
	
	func check_for_self(symbol, effect, symbols):
		match position:
			"row":
				symbols = tb.get_row(reels, symbol, true, index)
			"column":
				symbols = tb.get_column(reels, symbol, true, index)
			"corner":
				symbols = tb.get_corners(reels)
			"edge":
				symbols = tb.get_edges(reels)
		if symbol in symbols:
			return true
		return false
	
	
	func check_for_other(symbol, effect, i, symbols) -> bool:
		if relative:
			return check_relative_other(symbol, effect, i, symbols)
		else:
			return check_absolute_other(symbol, effect, i, symbols)
	
	
	func check_relative_other(symbol, effect, i, symbols):
		match position:
			"adjacent":
				symbols = i.get_adjacent_icons()
			"row":
				symbols = tb.get_row(reels, i, false)
			"column":
				symbols = tb.get_column(reels, i, false)
			"corner":
				symbols = tb.get_corners(reels)
			"edge":
				symbols = tb.get_edges(reels)
			"above":
				symbols = tb.get_above(reels, i)
			"below":
				symbols = tb.get_below(reels, i)
			"left":
				symbols = tb.get_left(reels, i)
			"right":
				symbols = tb.get_right(reels, i)
			"diagonal":
				symbols = tb.get_diagonals(reels, i)
		
		var filtered = symbols.duplicate()
		
		for i in symbols:
			if type:
				if i.type == "empty" and type != "empty":
					filtered.erase(i)
				elif i.type != type:
					filtered.erase(i)
			else:
				if i.type == "empty":
					filtered.erase(i)
			if group:
				if not group in i.groups:
					filtered.erase(i)
		
		if not operator:
			operator = "at_least"
		
		if operator == "every":
			return filtered.size() == symbols.size()
		else:
			if filtered.has(symbol):
				filtered.erase(symbol)
		
		return apply_operator(operator, filtered.size(), value if value >= 0 else 1.0)
	
	
	func check_absolute_other(symbol, effect, i, symbols):
		match position:
			"row":
				symbols = tb.get_row(reels, symbol, false, index)
			"column":
				symbols = tb.get_column(reels, symbol, false, index)
			"corner":
				symbols = tb.get_corners(reels)
			"edge":
				symbols = tb.get_edges(reels)
		
		if i in symbols:
			return true
		return false
	
	
	func check_for_any(symbol, effect, symbols : Array):
		match position:
			"adjacent":
				symbols = symbol.get_adjacent_icons()
			"row":
				symbols = tb.get_row(reels, symbol, false, index)
			"column":
				symbols = tb.get_column(reels, symbol, false, index)
			"corner":
				symbols = tb.get_corners(reels)
			"edge":
				symbols = tb.get_edges(reels)
			"above":
				symbols = tb.get_above(reels, symbol)
			"below":
				symbols = tb.get_below(reels, symbol)
			"left":
				symbols = tb.get_left(reels, symbol)
			"right":
				symbols = tb.get_right(reels, symbol)
			"diagonal":
				symbols = tb.get_diagonals(reels, symbol)
		
		var filtered = symbols.duplicate()
		
		for i in symbols:
			if type:
				if i.type == "empty" and type != "empty":
					filtered.erase(i)
				elif i.type != type:
					filtered.erase(i)
			else:
				if i.type == "empty":
					filtered.erase(i)
			if group:
				if not group in i.groups:
					filtered.erase(i)
		
		if not operator:
			operator = "at_least"
		
		if operator == "every":
			return symbols.size() == filtered.size()
		else:
			if filtered.has(symbol):
				filtered.erase(symbol)
		
		return apply_operator(operator, filtered.size(), value if value >= 0 else 1.0)
	
	
	func get_description():
		var to_return : String
		match target:
			"self":
				to_return = get_desc_self()
			"other":
				to_return = get_desc_other()
			"any":
				to_return = get_desc_any()
		return to_return
	
	
	func get_desc_self():
		var a : String = "if this symbol is%s"%[" not" if invert else ""]
		var b : String
		var c : String
		match position:
			"row":
				match index:
					0:
						b = "top"
					1:
						b = "second"
					2:
						b = "third"
					3:
						b = "bottom"
				c = "in the %s row"%b
			"column":
				match index:
					0:
						b = "leftmost"
					1:
						b = "second"
					2:
						b = "middle"
					3:
						b = "fourth"
					4:
						b = "rightmost"
				c = "in the %s column"%b
			"corner":
				c = "in a corner"
			"edge":
				c = "on an edge"
			_:
				return "something went wrong"
		return modsymbol.join(a, c)
	
	
	func get_desc_other():
		var a : String
		var b : String
		var c : String
		var d : String
		if relative:
			if operator == "every":
				a = tb.descriptions[position]["nega"] if invert else tb.descriptions[position]["text"]
				b = tb.clean_desc(a, position).replace("?", "symbol").replace("this", "that")
				c = get_type_or_group(self, true, "or")
				if not c:
					c = "not <icon_empty>"
				return "if every %s is %s"%[b, c]
			else:
				a = "is" if value == 1.0 else "are"
				b = operator.replace("_", " ")
				c = get_type_or_group(self, true, "or")
				if not c:
					c = "symbols"
				d = tb.descriptions[position]["nega"] if invert else tb.descriptions[position]["text"]
				d = tb.clean_desc(d, position).replace("?", c).replace("this", "that")
				return "if there %s %s <color_E14A68>%s<end> %s"%[a, b, value, d]
		else:
			a = "if that symbol is%s"%[" not" if invert else ""]
			match position:
				"row":
					match index:
						0:
							b = "top"
						1:
							b = "second"
						2:
							b = "third"
						3:
							b = "bottom"
					c = "in the %s row"%b
				"column":
					match index:
						0:
							b = "leftmost"
						1:
							b = "second"
						2:
							b = "middle"
						3:
							b = "fourth"
						4:
							b = "rightmost"
					c = "in the %s column"%b
				"corner":
					c = "in a corner"
				"edge":
					c = "on an edge"
			return modsymbol.join(a, c)
	
	
	func get_desc_any():
		var a : String
		var b : String
		var c : String
		var d : String
		if operator == "every":
			a = tb.descriptions[position]["nega"] if invert else tb.descriptions[position]["text"]
			b = tb.clean_desc(a, position).replace("?", "symbol")
			c = get_type_or_group(self, true, "or")
			if not c:
				c = "not <icon_empty>"
			return "if every %s is %s"%[b, c]
		else:
			a = "is" if value == 1.0 else "are"
			b = operator.replace("_", " ")
			c = get_type_or_group(self, true, "or")
			if not c:
				c = "symbols"
			d = tb.descriptions[position]["nega"] if invert else tb.descriptions[position]["text"]
			d = tb.clean_desc(d, position).replace("?", c)
			return "if there %s %s <color_E14A68>%s<end> %s"%[a, b, value, d]


class SymbolCountCondition extends Condition:
	var type : String
	var group : String
	var source : String
	
	
	func _init(modsymbol, dict : Dictionary).(modsymbol):
		if !dict.has("operator"):
			printerr("EBP ERROR: An operator must be given for the given condition 'symbol_count'")
			return
		if dict.has("type"):
			self.type = dict["type"]
		if dict.has("group"):
			self.group = dict["group"]
		self.source = dict["source"] if dict.has("source") and dict["source"] in ["reels", "inventory"] else "reels"
		self.valid = true
	
	
	func check_condition(symbol, effect, i = null):
		var result := false
		var symbol_count : int = 0
		if type:
			symbol_count = modsymbol.count_symbols(source, {"type": type})
		elif group:
			symbol_count = modsymbol.count_symbols(source, {"group": group})
		else:
			symbol_count = modsymbol.count_symbols(source)
		if operator == "every":
			if not type and not group:
				return false
			else:
				result = apply_operator("exactly", symbol_count, modsymbol.count_symbols(source))
		else:
			result = apply_operator(operator, symbol_count, value)
		
		return !result if invert else result
	
	
	func get_description():
		var a : String = "is" if value == 1.0 else "are"
		var b : String = operator.replace("_", " ")
		var c : String = get_type_or_group(self, true, "or")
		var d : String = " in your inventory" if source == "inventory" else ""
		return "if there %s %s <color_E14A68>%s<end> %s%s"%[a, b, value, c, d]


class SymbolValueCondition extends Condition:
	const valid_value_types = ["value", "final_value", "value_bonus"]
	var value_type : String
	
	func _init(modsymbol, dict : Dictionary).(modsymbol):
		if !dict.has("operator"):
			printerr("EBP ERROR: An 'operator' must be given for the given condition")
			return
		if !dict.has("value") or not float(dict["value"]):
			printerr("EBP ERROR: An integer 'value' must be given for the given condition")
			return
		if dict.has("value_type"):
			if dict["value_type"] in valid_value_types:
				self.value_type = dict["value_type"]
			else:
				printerr("EBP WARNING: 'value_type' of '%s' is not one of the valid types: %s. Setting to default value, continuing..."%[dict["value_type"], valid_value_types])
		self.valid = true
	
	
	func check_condition(symbol, effect, i = null):
		var result := false
		match operator:
			"exactly":
				effect = effect.if_property_equals(value_type, value)
			"at_least":
				effect = effect.if_property_at_least(value_type, value)
			"less_than":
				effect = effect.if_property_less_than(value_type, value)
			_:
				result = false
		result = true
		
		return !result if invert else result
	
	
	func get_description():
		var a : String = "its" if target and target == "other" else "this symbol's"
		var b : String = operator.replace("_", " ")
		var c : String = "base value"
		match value_type:
			"final_value":
				c = "value"
			"value_bonus":
				c = "bonus value"
			_:
				"base value"
		return "if %s %s is %s %s"%[a, c, b, value]


class TurnCountCondition extends Condition:
	func _init(modsymbol, dict : Dictionary).(modsymbol):
		if !dict.has("operator"):
			printerr("EBP ERROR: An 'operator' must be given for the given condition 'turns'")
			return
		if !dict.has("value") or not float(dict["value"]):
			printerr("EBP ERROR: An integer 'value' must be given for the given condition 'turns'")
			return
		self.valid = true
	
	
	func check_condition(symbol, effect, i = null):
		var result
		match operator:
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
	
	
	func get_description():
		match operator:
			"exactly":
				return "after exactly <color_E14A68>%s<end> spins"%value
			"at_least":
				return "after <color_E14A68>%s<end> spins"%value
			"less_than":
				return "if this symbol has appeared fewer than <color_E14A68>%s<end> times"%value
			"every":
				return "every <color_E14A68>%s<end> spins"%value
