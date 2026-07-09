-- ADHD trait registration.
-- Perk boosts double as the guaranteed movement-speed buff: vanilla ground
-- speed scales with Fitness/Sprinting/Nimble levels (same mechanism as the
-- Athletic trait), so this works even if no direct speed modifier API exists.
local function addADHDTrait()
	-- Cost must be non-zero or the trait shows in neither column of the creation
	-- screen (game buckets Good=cost>0, Bad=cost<0, and drops cost==0 entirely).
	-- Negative => appears in "Bad Traits" and grants points; flip the sign to
	-- make it a costly "Good" trait instead.
	local trait = TraitFactory.addTrait("ADHD", getText("UI_trait_ADHD"), -6,
		getText("UI_trait_ADHDDesc"), false)
	trait:addXPBoost(Perks.Fitness, 2)
	trait:addXPBoost(Perks.Sprinting, 3)
	trait:addXPBoost(Perks.Nimble, 3)
	TraitFactory.sortList()
end

Events.OnGameBoot.Add(addADHDTrait)
