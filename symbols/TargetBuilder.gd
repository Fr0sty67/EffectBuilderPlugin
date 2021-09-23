const valid_keys = [
	"adjacent", "row", "column", "all",
	"self", "corner", "edge", "above", "below",
	"left", "right", "diagonal"
]
const valid_args = [true, false]
const descriptions = {
	"adjacent" : {
		"text" : "adjacent ?",
		"nega" : "non-adjacent ?",
	},
	"row" : {
		"text" : "? in the # row",
		"nega" : "? not in the # row",
	},
	"column" : {
		"text" : "? in the # column",
		"nega" : "? not in the # column",
	},
	"all" : {
		"text" : "all ?",
		"nega" : "none of (wtf are you doing) ?",
	},
	"self" : {
		"text" : "",
		"nega" : "all other ?",
	},
	"corner" : {
		"text" : "? in a corner",
		"nega" : "? not in a corner",
	},
	"edge" : {
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


static func parse(modsymbol, target_dict : Dictionary) -> TargetGroup:
	var tg = TargetGroup.new()
	for key in target_dict.keys():
		if not key in valid_keys:
			push_error("Invalid key value '%s', expected one of %s"%[key, valid_keys])
			return tg.clear()
		if target_dict[key].has("not"):
			if not target_dict[key]["not"] in valid_args:
				push_error("Invalid argument '%s', expected one of %s"%[target_dict[key]["not"], valid_args])
				return tg.clear()
		else:
			target_dict[key]["not"] = false
		if target_dict[key].has("include_self"):
			if not target_dict[key]["include_self"] in valid_args:
				push_error("Invalid argument '%s', expected one of %s"%[target_dict[key]["not"], valid_args])
				return tg.clear()
		tg.add_target(Target.new(modsymbol, key, target_dict[key]))
	return tg


static func get_row(reels, symbol, include_self = false, index = null) -> Array:
	var symbols := []
	var final_idx = index if index >= 0 else symbol.grid_position.y
	for x in range(reels.reel_width):
		symbols.push_back(reels.displayed_icons[final_idx][x])
	if !include_self and symbols.has(symbol):
		symbols.erase(symbol)
	return symbols


static func get_column(reels, symbol, include_self = false, index = null) -> Array:
	var symbols := []
	var final_idx = index if index >= 0 else symbol.grid_position.x
	for y in range(reels.reel_height):
		symbols.push_back(reels.displayed_icons[y][final_idx])
	if !include_self and symbols.has(symbol):
		symbols.erase(symbol)
	return symbols


static func get_left(reels, symbol) -> Array:
	var symbols := []
	for x in range(reels.reel_width):
		if x > symbol.grid_position.x:
			continue
		symbols.push_back(reels.displayed_icons[symbol.grid_position.y][x])
	return symbols


static func get_right(reels, symbol) -> Array:
	var symbols := []
	for x in range(reels.reel_width):
		if x < symbol.grid_position.x:
			continue
		symbols.push_back(reels.displayed_icons[symbol.grid_position.y][x])
	return symbols


static func get_above(reels, symbol) -> Array:
	var symbols := []
	for y in range(reels.reel_height):
		if y > symbol.grid_position.y:
			continue
		symbols.push_back(reels.displayed_icons[y][symbol.grid_position.x])
	return symbols


static func get_below(reels, symbol) -> Array:
	var symbols := []
	for y in range(reels.reel_height):
		if y < symbol.grid_position.y:
			continue
		symbols.push_back(reels.displayed_icons[y][symbol.grid_position.x])
	return symbols


static func get_diagonals(reels, symbol):
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
		while symbol.grid_position.x + x_mod >= 0 \
		and symbol.grid_position.y + y_mod >= 0 \
		and symbol.grid_position.x + x_mod <= reels.reel_width - 1 \
		and symbol.grid_position.y + y_mod <= reels.reel_height - 1:
			symbols.push_back(reels.displayed_icons[symbol.grid_position.y + y_mod][symbol.grid_position.x + x_mod])
			x_mod += x_diff
			y_mod += y_diff
	return symbols


static func get_all(reels, symbol, include_self = false) -> Array:
	var symbols := []
	for row in reels.displayed_icons:
		symbols += row
	if !include_self:
		symbols.erase(symbol)
	return symbols


static func get_corners(reels) -> Array:
	var symbols := []
	symbols.push_back(reels.displayed_icons[0][0])
	symbols.push_back(reels.displayed_icons[0][reels.reel_width -1])
	symbols.push_back(reels.displayed_icons[reels.reel_height - 1][0])
	symbols.push_back(reels.displayed_icons[reels.reel_height - 1][reels.reel_width - 1])
	return symbols


static func get_edges(reels) -> Array:
	var symbols := []
	for row in reels.displayed_icons:
		for s in row:
			if s.grid_position.y == 0 \
			or s.grid_position.x == 0 \
			or s.grid_position.y == reels.reel_height - 1 \
			or s.grid_position.x == reels.reel_width -1:
				symbols.push_back(s)
	return symbols


class TargetGroup:
	var targets := []
	
	
	func _init():
		pass
	
	
	func add_target(target : Target):
		targets.push_back(target)
	
	
	func build(symbol, adjacent):
		var symbols := []
		for i in targets:
			symbols += i.build(symbol, adjacent)
		return symbols
	
	
	func clear():
		targets.clear()
		return self
	
	
	func get_description():
		var desc := ""
		for target in targets:
			var inner : String = target.get_description()
			if !desc:
				desc = inner
			else:
				desc += " or " + inner.replace("? ", "")
		return desc


class Target:
	var modsymbol
	var reels
	var type : String
	var invert := false
	var include_self := false
	var tb
	var index := -1
	
	
	func _init(modsymbol, key : String, dict : Dictionary):
		self.modsymbol = modsymbol
		self.tb = modsymbol.cbldr.tbldr
		self.reels = modsymbol.modloader.globals.reels
		self.type = key
		if dict.has("not"):
			self.invert = dict["not"]
		if dict.has("include_self"):
			self.include_self = dict["include_self"]
		if dict.has("index"):
			self.index = dict["index"]
			if type == "row":
				self.index = dict["index"]
				if not index in range(reels.reel_height):
					printerr("EBP ERROR: Invalid index '%s', must be between 0 and %s"%[index, reels.reel_height])
					return
			elif type == "column":
				self.index = dict["index"]
				if not index in range(reels.reel_width):
					printerr("EBP ERROR: Invalid index '%s', must be between 0 and %s"%[index, reels.reel_width])
					return
	
	
	func build(symbol, adjacent):
		var symbols := []
		match type:
			"adjacent":
				symbols = adjacent
			"row":
				symbols = tb.get_row(reels, symbol, include_self, index)
			"column":
				symbols = tb.get_column(reels, symbol, include_self, index)
			"all":
				symbols = tb.get_all(reels, symbol, include_self)
			"self":
				symbols.push_back(symbol)
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
		if invert:
			symbols = modsymbol.subtract(tb.get_all(reels, symbol, true), symbols)
		return symbols
	
	
	func get_description():
		var desc : String = tb.descriptions[type]["nega"] if invert else tb.descriptions[type]["text"]
		desc = clean_desc(desc, type)
		return desc
	
	
	func clean_desc(desc, desc_type):
		var replace := "same"
		if desc_type == "row":
			match index:
				0: replace = "top"
				1: replace = "second"
				2: replace = "third"
				3: replace = "bottom"
		if desc_type == "column":
			match index:
				0: replace = "leftmost"
				1: replace = "second"
				2: replace = "midlle"
				3: replace = "fourth"
				4: replace = "rightmost"
		return desc.replace("#", replace)
