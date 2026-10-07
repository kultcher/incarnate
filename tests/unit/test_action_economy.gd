extends GutTest


func test_two_moves_uses_flex() -> void:
	var a := ActionEconomy.new()
	a.pay(Enums.Cost.MOVE)
	assert_eq(a.move, 0)
	assert_true(a.can_pay(Enums.Cost.MOVE), "Flex covers a second move")
	a.pay(Enums.Cost.MOVE)
	assert_eq(a.flex, 0)
	assert_false(a.can_pay(Enums.Cost.MOVE))
	assert_true(a.can_pay(Enums.Cost.SKILL), "Skill point is untouched")


func test_two_skills_uses_flex() -> void:
	var a := ActionEconomy.new()
	a.pay(Enums.Cost.SKILL)
	a.pay(Enums.Cost.SKILL)
	assert_false(a.can_pay(Enums.Cost.SKILL))
	assert_true(a.can_pay(Enums.Cost.MOVE))


func test_free_never_costs() -> void:
	var a := ActionEconomy.new()
	a.pay(Enums.Cost.MOVE)
	a.pay(Enums.Cost.MOVE)
	a.pay(Enums.Cost.SKILL)
	assert_true(a.is_spent())
	assert_true(a.can_pay(Enums.Cost.FREE))


func test_refresh() -> void:
	var a := ActionEconomy.new()
	a.pay(Enums.Cost.MOVE)
	a.pay(Enums.Cost.SKILL)
	a.refresh()
	assert_eq([a.move, a.skill, a.flex], [1, 1, 1])
