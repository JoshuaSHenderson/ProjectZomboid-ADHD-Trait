-- Stand still for 15 real seconds with the ADHD trait -> die infected and reanimate.
-- "Active" = moved, has a queued/running timed action, or is aiming/attacking.
local CHECK_MS = 250
-- a frame gap bigger than this means pause/loading/fast-forward; don't count it as idle time
local GAP_RESET_MS = 2000
local WARN_LEAD_MS = 5000 -- show the countdown warning for the final N ms before death

-- kill time is sandbox-configurable (seconds); default 15 if unset
local function getKillMs()
	local secs = SandboxVars.ADHD and SandboxVars.ADHD.KillSeconds or 15
	return secs * 1000
end

local state = {} -- [playerNum] = { x, y, lastActive, lastCheck }

local function isActive(player, s)
	if math.abs(player:getX() - s.x) > 0.01 or math.abs(player:getY() - s.y) > 0.01 then
		return true -- covers walking, running, and moving vehicles; a parked car counts as standing still
	end
	local actions = player:getCharacterActions()
	if actions and not actions:isEmpty() then
		return true
	end
	if player:isAiming() or player:isAttacking() then
		return true
	end
	return false
end

local function zombify(player)
	local bd = player:getBodyDamage()
	bd:setInfected(true)
	bd:setInfectionLevel(99.9) -- dying fully Knox-infected reanimates via the vanilla pipeline
	player:Kill(player)
end

Events.OnCreatePlayer.Add(function(playerNum, player)
	state[playerNum] = nil
end)

Events.OnPlayerUpdate.Add(function(player)
	if player:isDead() or player:isGodMod() or not player:HasTrait("ADHD") then return end

	local now = getTimestampMs()
	local num = player:getPlayerNum()
	local s = state[num]
	if not s then
		state[num] = { x = player:getX(), y = player:getY(), lastActive = now, lastCheck = now }
		return
	end
	if now - s.lastCheck < CHECK_MS then return end
	if now - s.lastCheck > GAP_RESET_MS then
		s.lastActive = now
	end
	s.lastCheck = now

	if isActive(player, s) then
		s.lastActive = now
	end
	s.x, s.y = player:getX(), player:getY()

	local killMs = getKillMs()
	local idle = now - s.lastActive
	if idle >= killMs then
		s.lastActive = now
		zombify(player)
	elseif idle >= killMs - WARN_LEAD_MS then
		player:setHaloNote("MOVE! " .. math.ceil((killMs - idle) / 1000), 255, 60, 60, 300)
	end
end)
