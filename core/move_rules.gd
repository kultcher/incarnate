class_name MoveRules
extends RefCounted
## Parameters for one kind of movement: walk, shift, fly and so on.

var pass_through: Enums.PassThrough = Enums.PassThrough.ALLIES
var ignore_terrain_cost: bool = false


static func walk() -> MoveRules:
	return MoveRules.new()


static func shift() -> MoveRules:
	var rules := MoveRules.new()
	rules.pass_through = Enums.PassThrough.ALL
	return rules
