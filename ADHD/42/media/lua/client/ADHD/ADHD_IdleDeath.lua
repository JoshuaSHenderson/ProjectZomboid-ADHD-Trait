-- Stand still too long with the ADHD trait -> die infected and reanimate.
-- "Active" = moved, has a queued/running timed action, or is aiming/attacking.
local CHECK_MS = 250
-- a frame gap bigger than this means pause/loading/fast-forward; don't count it as idle time
local GAP_RESET_MS = 2000
local WARN_LEAD_MS = 5000 -- panic countdown + alarm for the final N ms before death

-- Vanilla FMOD sound (loops until stopped) — loud, unmistakable, no custom audio assets needed.
local ALARM_SOUND = "AlarmClockRingingLoop"

-- One line per second remaining; the character audibly losing it.
local PANIC_LINES = {
	[5] = "no no no NO— I have to MOVE!",
	[4] = "skin's CRAWLING, legs GO, GO!",
	[3] = "I CAN'T DO STILL— MOVE!!",
	[2] = "HEART'S SLAMMING— MOVE NOW!!",
	[1] = "MOVE MOVE MOVE MOVE!!!",
}

-- kill time is sandbox-configurable (seconds); default 15 if unset
local function getKillMs()
	local secs = SandboxVars.ADHD and SandboxVars.ADHD.KillSeconds or 15
	return secs * 1000
end

local state = {} -- [playerNum] = { x, y, lastActive, lastCheck, alarm }

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

local function stopAlarm(player, s)
	if s.alarm then
		player:getEmitter():stopSound(s.alarm)
		s.alarm = nil
	end
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
		stopAlarm(player, s)
	end
	s.x, s.y = player:getX(), player:getY()

	local killMs = getKillMs()
	local idle = now - s.lastActive
	if idle >= killMs then
		s.lastActive = now
		stopAlarm(player, s)
		zombify(player)
	elseif idle >= killMs - WARN_LEAD_MS then
		if not s.alarm then
			s.alarm = player:getEmitter():playSound(ALARM_SOUND)
		end
		local secsLeft = math.ceil((killMs - idle) / 1000)
		local line = PANIC_LINES[secsLeft] or PANIC_LINES[5]
		player:setHaloNote(line .. " " .. secsLeft, 255, 60, 60, 300)
	end
end)
