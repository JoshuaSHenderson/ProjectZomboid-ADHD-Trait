-- Build 42 defines the trait in two places (the old TraitFactory API is gone):
--   media/registries.lua        -> registers the CharacterTrait object itself
--   media/scripts/adhd_trait.txt -> the CharacterTraitDefinition (cost, UI, boosts)
-- This file just hands the rest of the mod the CharacterTrait object, because
-- character:hasTrait() takes the object, not a name.
--
-- The perk boosts declared in the script (Fitness/Sprinting/Nimble) are still
-- the guaranteed movement-speed buff: vanilla ground speed scales with those
-- levels, same mechanism as the Athletic trait.
--
-- Cost is negative in the script, so the trait lists under "Bad Traits" and
-- grants points; flip the sign there to make it a costly "Good" trait instead.
ADHD = ADHD or {}

local TRAIT_ID = "adhd:adhd"
local TRAIT_NAME = "adhd" -- ResourceLocation path, i.e. what CharacterTrait:getName() returns

ADHD.TRAIT_ID = TRAIT_ID
ADHD.UINAME = "UI_trait_adhd"

-- registries.lua runs in this same Lua state, so ADHD.TRAIT is normally already
-- set by the time anything here is called. The scan is the fallback for the case
-- where a Lua reset re-runs the scripts but not the registries.
function ADHD.getTrait()
	if ADHD.TRAIT then return ADHD.TRAIT end
	local defs = CharacterTraitDefinition.getTraits()
	for i = 0, defs:size() - 1 do
		local t = defs:get(i):getType()
		local name = t:getName()
		if name == TRAIT_NAME or name == TRAIT_ID then
			ADHD.TRAIT = t
			return t
		end
	end
	return nil
end

function ADHD.getDefinition()
	local t = ADHD.getTrait()
	return t and CharacterTraitDefinition.getCharacterTraitDefinition(t) or nil
end

function ADHD.hasTrait(character)
	if not character then return false end
	local t = ADHD.getTrait()
	return t ~= nil and character:hasTrait(t)
end
