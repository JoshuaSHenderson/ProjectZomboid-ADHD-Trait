-- Force the ADHD trait on players listed in SandboxVars.ADHD.ForcedUsernames.
-- Comma-separated usernames; "*" forces everyone; empty forces nobody.
-- In singleplayer there is no online username, so ANY non-empty value forces
-- the trait.
-- Two layers:
--   1. Creation-screen enforcement: every frame the screen renders, if the
--      trait isn't selected, select it through the vanilla addTrait path
--      (points, mutual exclusions and sorting all handled by vanilla code).
--      Deselecting/resetting just re-adds it next frame, so the vanilla
--      reset/randomize loops can never deadlock against us.
--   2. Guaranteed backstop on OnCreatePlayer.

local function isForced()
	local raw = SandboxVars.ADHD and SandboxVars.ADHD.ForcedUsernames or ""
	if raw == "" then return false end
	if not isClient() then return true end -- singleplayer: no username to match
	local username = getOnlineUsername()
	for name in string.gmatch(raw, "([^,]+)") do
		name = name:trim()
		if name == "*" then return true end
		if username and name == username then return true end
	end
	return false
end

-- Layer 1: creation-screen enforcement.
-- ADHD has a negative cost, so it lives in listboxBadTrait.
local function findADHD(list)
	if not list or not list.items then return nil end
	for i = 1, #list.items do
		local it = list.items[i]
		if it.item and it.item.getType and it.item:getType() == "ADHD" then
			return i
		end
	end
	return nil
end

if CharacterCreationProfession and CharacterCreationProfession.prerender then
	local origPrerender = CharacterCreationProfession.prerender
	function CharacterCreationProfession:prerender(...)
		origPrerender(self, ...)
		if not isForced() then return end
		if findADHD(self.listboxTraitSelected) then return end -- already selected
		local i = findADHD(self.listboxBadTrait)
		if i then
			self.listboxBadTrait.selected = i
			self:addTrait(true)
			self:checkXPBoost()
		end
	end
end

-- Layer 2: guaranteed backstop. Also apply the trait's perk boosts manually,
-- since traits added after creation don't grant their starting levels.
Events.OnCreatePlayer.Add(function(playerNum, player)
	if not isForced() or player:HasTrait("ADHD") then return end
	player:getTraits():add("ADHD")
	local boosts = { [Perks.Fitness] = 2, [Perks.Sprinting] = 3, [Perks.Nimble] = 3 }
	for perk, levels in pairs(boosts) do
		for _ = 1, levels do
			player:LevelPerk(perk)
		end
	end
end)
