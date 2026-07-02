-- All timed actions run ~3x faster for ADHD characters.
-- adjustMaxTime is the vanilla hook (B41.73+) every ISBaseTimedAction
-- subclass passes its duration through.
local ADHD_origAdjustMaxTime = ISBaseTimedAction.adjustMaxTime

function ISBaseTimedAction:adjustMaxTime(maxTime)
	local t = ADHD_origAdjustMaxTime(self, maxTime)
	-- t <= 0 means an indefinite action (e.g. sleeping/forever actions); leave those alone
	if t and t > 0 and self.character and self.character.HasTrait
			and self.character:HasTrait("ADHD") then
		t = t / 3
	end
	return t
end
