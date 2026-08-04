-- Build 42 resolves `CharacterTrait = adhd:adhd` in media/scripts/adhd_trait.txt
-- against Registries.CHARACTER_TRAIT. Nothing registers mod traits automatically,
-- so without this file the script load dies with:
--   NullPointerException: ... CharacterTrait.getName() because "this.characterTraitType" is null
-- media/registries.lua is run before the scripts are parsed, which is the only
-- window where this registration is useful.
ADHD = ADHD or {}
ADHD.TRAIT = CharacterTrait.register("adhd:adhd")
