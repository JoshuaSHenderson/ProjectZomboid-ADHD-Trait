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
	for entry in string.gmatch(raw, "([^,]+)") do
		-- trim is a Java String method, not a Lua one, so do it with a pattern
		local name = entry:match("^%s*(.-)%s*$")
		if name == "*" then return true end
		if username and name == username then return true end
	end
	return false
end

-- Layer 1: creation-screen enforcement.
-- ADHD has a negative cost, so it lives in listboxBadTrait.
-- List items hold CharacterTraitDefinitions. Registry entries are singletons, so
-- comparing the CharacterTrait objects with == is the vanilla idiom (see
-- CharacterCreationProfession:isTraitEnabled).
local function findADHD(list)
	local trait = ADHD.getTrait()
	if not trait or not list or not list.items then return nil end
	for i = 1, #list.items do
		local it = list.items[i]
		if it.item and it.item.getType and it.item:getType() == trait then
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
			-- B42 addTrait takes the trait definition itself, and repopulates the lists
			self:addTrait(self.listboxBadTrait.items[i].item)
			self:checkXPBoost()
		end
	end
end

-- Layer 2: guaranteed backstop. Also apply the trait's XP boosts, since traits
-- added after creation don't grant their starting levels.
Events.OnCreatePlayer.Add(function(playerNum, player)
	local trait = ADHD.getTrait()
	if not trait or not isForced() or player:hasTrait(trait) then return end
	player:getCharacterTraits():add(trait)
	-- same order vanilla uses in ISPlayerStatsUI:onAddTrait; both calls take the
	-- CharacterTrait, not the definition. Second arg is "is this trait being
	-- removed", so false = grant the boosts.
	player:modifyTraitXPBoost(trait, false)
	SyncXp(player)
end)
