-- Timed actions run faster for ADHD characters (sandbox-configurable multiplier).
-- adjustMaxTime is the vanilla hook (B41.73+) every ISBaseTimedAction
-- subclass passes its duration through.
local ADHD_origAdjustMaxTime = ISBaseTimedAction.adjustMaxTime

local function getMultiplier()
	local m = SandboxVars.ADHD and SandboxVars.ADHD.ActionSpeedMultiplier or 3
	if not m or m < 1 then m = 1 end
	return m
end

function ISBaseTimedAction:adjustMaxTime(maxTime)
	local t = ADHD_origAdjustMaxTime(self, maxTime)
	-- t <= 0 means an indefinite action (e.g. sleeping/forever actions); leave those alone
	if t and t > 0 and self.character and self.character.HasTrait
			and self.character:HasTrait("ADHD") then
		t = t / getMultiplier()
	end
	return t
end
