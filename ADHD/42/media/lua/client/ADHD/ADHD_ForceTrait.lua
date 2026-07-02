-- Force the ADHD trait on players listed in SandboxVars.ADHD.ForcedUsernames.
-- Comma-separated usernames; "*" forces everyone; empty forces nobody.
-- Two layers:
--   1. Best-effort UI lock in the character creation screen (pcall-guarded;
--      creation UI internals differ between builds and may change).
--   2. Guaranteed backstop on OnCreatePlayer.

local function isForced()
	local raw = SandboxVars.ADHD and SandboxVars.ADHD.ForcedUsernames or ""
	if raw == "" then return false end
	local username = isClient() and getOnlineUsername() or nil
	for name in string.gmatch(raw, "([^,]+)") do
		name = name:trim()
		if name == "*" then return true end
		if username and name == username then return true end
	end
	return false
end

-- Layer 1: pre-select and lock the trait in the creation screen (best effort).
-- ponytail: pcall-guarded because listbox internals vary between B41 and B42;
-- if this breaks on a build, the OnCreatePlayer backstop below still enforces it.
if CharacterCreationProfession then
	local origInitialise = CharacterCreationProfession.initialise
	function CharacterCreationProfession:initialise(...)
		origInitialise(self, ...)
		if not isForced() then return end
		pcall(function()
			for i = 1, #self.listboxTrait.items do
				local it = self.listboxTrait.items[i]
				if it.item and it.item.getType and it.item:getType() == "ADHD" then
					self.listboxTraitSelected:addItem(it.text, it.item)
					self.listboxTrait:removeItem(it.text)
					break
				end
			end
		end)
	end

	-- block deselecting the forced trait
	local origDblClick = CharacterCreationProfession.onDblClickTraitSelected
	if origDblClick then
		function CharacterCreationProfession:onDblClickTraitSelected(item, ...)
			if isForced() and item and item.getType and item:getType() == "ADHD" then
				return
			end
			return origDblClick(self, item, ...)
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
