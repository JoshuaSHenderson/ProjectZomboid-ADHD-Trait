-- Best-effort direct movement-speed modifier for ADHD characters.
-- ponytail: the guaranteed speed buff is the perk boosts in ADHD_Trait.lua;
-- this file only tries the direct Java modifier once per player and shrugs
-- if the build doesn't expose it. Upgrade path: build-specific API once
-- verified in-game per build.
local tried = {}

Events.OnCreatePlayer.Add(function(playerNum, player)
	tried[playerNum] = nil
end)

Events.OnPlayerUpdate.Add(function(player)
	if not player:isLocalPlayer() then return end -- never touch remote players in MP
	local num = player:getPlayerNum()
	if tried[num] then return end
	tried[num] = true
	if not player:HasTrait("ADHD") then return end
	pcall(function()
		player:setRunSpeedModifier(1.4)
	end)
end)
