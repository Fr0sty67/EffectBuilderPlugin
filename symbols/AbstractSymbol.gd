extends "res://modloader/ModSymbol.gd"
const builder = preload("res://effects-builder-plugin/symbols/ComponentBuilder.gd")

var rng := RandomNumberGenerator.new()
var destroys : Array = [] # of Destroyer
var adds : Array = [] # of Spawnables
var buffs : Array = [] # of Buff
var transforms : Array = [] # of Transformable
var flavor_text : String


func init(modloader: Reference, params):
	self.modloader = modloader
	rng.randomize()


func get_description():
	var desc = ""
	if destroys:
		for i in destroys:
			desc = join(desc, i.get_description())
	if adds:
		for i in adds:
			desc = join(desc, i.get_description())
	if buffs:
		for i in buffs:
			desc = join(desc, i.get_description())
	if transforms:
		for i in transforms:
			desc = join(desc, i.get_description())
	return desc


func get_flavor_text():
	return "\n<color_666666>%s<end>"%flavor_text if flavor_text else ""


func add_conditional_effects(symbol, adjacent):
	if destroys:
		for i in destroys:
			i.construct(effect(), symbol, adjacent)
	
	if buffs:
		for i in buffs:
			i.construct(effect(), symbol, adjacent)
	
	if transforms:
		for i in transforms:
			if not i.new_type and not i.new_group:
				printerr("Must supply either new_type or new_group to transforms symbols, skipping...")
				return
			i.construct(effect(), symbol, adjacent)
	
	if adds:
		for i in adds:
			if not i.new_type and not i.new_group:
				printerr("Must supply either type or group to spawn symbols, skipping...")
				return
			i.construct(effect(), symbol, adjacent)


func destroy():
	return builder.Destroyer.new(self)


func add():
	return builder.Spawnable.new(self)


func transform():
	return builder.Transformable.new(self)


func buff():
	return builder.Buff.new(self)


func condition():
	return builder.Condition.new(self)
