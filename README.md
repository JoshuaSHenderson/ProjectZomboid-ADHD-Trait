# ADHD Trait — Project Zomboid Mod

Adds a new character trait, **ADHD**, that trades raw speed for a lethal
inability to sit still.

- **Everything is faster.** All timed actions (crafting, reading, foraging,
  ripping clothes, disassembling, everything routed through the game's timed
  action system) complete faster — **3× by default, configurable 1–10× in
  Sandbox Options**. You also move faster.
- **Stillness kills.** Stand still too long and your character drops dead — and
  gets back up as a zombie. The idle limit defaults to **15 seconds** and is
  configurable in Sandbox Options. For the final seconds (default 5,
  configurable) a **loud ringing alarm** blares and a red panicked countdown
  flashes over your head
  ("no no no NO— I have to MOVE!" … "MOVE MOVE MOVE MOVE!!!").
- **Visible trait.** The trait has its own lightning-bolt icon and shows up in
  the character-creation trait list and on the in-game character info panel
  alongside your other traits.
- **Forceable.** Server admins can force the trait onto specific players (or
  everyone) from Sandbox Options — it appears pre-selected and locked in the
  character-creation screen.

Works on both **Build 41** and **Build 42**.

---

## What counts as "moving"?

The idle timer resets whenever you are actually doing something, so the trait is
playable. You are considered **active** when any of these is true:

- your character's position changed (walking, running, driving),
- you have a timed action queued or running (crafting, reading, etc.),
- you are aiming or attacking.

You are considered **idle** when none of the above hold. Notes:

- **Sitting in a parked vehicle counts as standing still** — keep it moving.
- **Pausing / fast-forwarding does not advance the timer.** The countdown uses
  real wall-clock time and ignores large frame gaps (pause, loading screens).

When the timer runs out, the character is set fully Knox-infected and killed, so
the corpse reanimates through the game's normal infection pipeline. If your
server's sandbox settings disable reanimation entirely, the player simply dies.

---

## Sandbox Options

Found under the **ADHD** page in Sandbox Options (single-player custom game,
or server `servertest_SandboxVars.lua`).

| Option | Type | Default | Description |
|---|---|---|---|
| **Action speed multiplier** (`ADHD.ActionSpeedMultiplier`) | double, 1.0–10.0 | `3.0` | How many times faster ADHD characters complete timed actions. `1` disables the speed-up. |
| **Seconds standing still before death** (`ADHD.KillSeconds`) | integer, 1–600 | `15` | How many real seconds an ADHD character may stand still before dying and reanimating. |
| **Seconds of warning before death** (`ADHD.WarnSeconds`) | integer, 1–60 | `5` | How many seconds before death the loud alarm and panic countdown kick in. |
| **Forced usernames** (`ADHD.ForcedUsernames`) | string | *(empty)* | Comma-separated list of usernames forced to take the ADHD trait at creation. `*` forces everyone. Empty means the trait is simply optional. |

### Forcing the trait

Set **Forced usernames** to force the trait on matching players:

```
ADHD.ForcedUsernames = "Alice,Bob"    -- only Alice and Bob
ADHD.ForcedUsernames = "*"            -- everyone
ADHD.ForcedUsernames = ""             -- nobody; trait is optional
```

For matched players the trait is auto-selected in the creation screen through
the game's own trait-selection code (points and mutual exclusions included) and
re-selected every frame — deselecting or resetting the build just snaps it
back. A guaranteed backstop re-applies it when the character spawns even if
the creation UI differs between builds.

> **Single-player note:** there is no online username offline, so **any
> non-empty value** (a name, or `*`) forces the trait in single-player. In
> multiplayer, exact names and `*` both work.

---

## Installation

### From a local copy

Copy the **inner** mod folder (`ADHD/Contents/mods/ADHD`) into your Zomboid
mods directory:

```
%USERPROFILE%\Zomboid\mods\ADHD\
```

Then enable **ADHD** in the in-game Mods menu, and add it to your server's
`Mods=` line for multiplayer.

### Folder layout

The repo's `ADHD/` folder is shaped exactly like a Steam Workshop item, with
both build layouts inside the mod:

```
ADHD/                                  ← Workshop item folder
├── workshop.txt                       # Workshop metadata (title/description/tags)
├── preview.png                        # 256x256 Workshop thumbnail
└── Contents/
    └── mods/
        └── ADHD/                      ← the actual mod
            ├── mod.info               # Build 41 manifest
            ├── media/                 # Build 41 content
            │   ├── sandbox-options.txt
            │   ├── ui/Traits/trait_adhd.png   # 18x18 trait icon
            │   └── lua/
            │       ├── shared/Translate/EN/   # trait + sandbox strings
            │       └── client/ADHD/           # trait logic (5 files)
            └── 42/
                ├── mod.info           # Build 42 manifest
                └── media/             # Build 42 content (mirror of the above)
```

Build 42 automatically reads the `42/` subfolder; Build 41 reads the root.

---

## How it works (files)

| File | Responsibility |
|---|---|
| `ADHD_Trait.lua` | Registers the trait (cost -6, so it lists under **Bad Traits** and grants points; flip the sign for a costly Good trait) with Fitness/Sprinting/Nimble XP boosts — these perk levels are the guaranteed movement-speed buff via the game's own speed formulas. |
| `ADHD_ActionSpeed.lua` | Wraps `ISBaseTimedAction:adjustMaxTime` to divide every timed action's duration by `ADHD.ActionSpeedMultiplier` (skips indefinite actions). |
| `ADHD_MoveSpeed.lua` | Best-effort direct `setRunSpeedModifier` bump, guarded so it's harmless if a build lacks the API. |
| `ADHD_IdleDeath.lua` | The idle timer: reads `ADHD.KillSeconds`, tracks activity, plays the alarm (vanilla `AlarmClockRingingLoop`, stopped when you move), shows the panic countdown, and zombifies on timeout. |
| `ADHD_ForceTrait.lua` | Reads `ADHD.ForcedUsernames`; auto-selects the trait in the creation screen every frame (via vanilla `addTrait`) and enforces it on spawn. |

---

## Uploading to the Steam Workshop

The Workshop uploader requires the mod nested inside `Contents/mods/`. Its
`Contents/` folder may contain **only** `mods`, `buildings`, or `creative` — any
other folder name (e.g. `media`, `42`, `mod.info` placed directly in `Contents`)
triggers:

> the following folders are the only ones permitted in contents: buildings/creative/mods

The repo's `ADHD/` folder is already in the uploader's expected shape, so the
upload folder is a straight copy (from a clone of this repo):

```powershell
Copy-Item -Recurse -Force ".\ADHD" "$env:USERPROFILE\Zomboid\Workshop\ADHD"
```

Then in-game: **Main Menu → Workshop → the ADHD item → Upload**. Leave
`id=` blank in `workshop.txt` for the first upload; Steam fills it in after.

## Known limitations

- Not yet verified in-game on either build; treat as beta. Creation-UI internals
  and the direct speed-modifier API may need per-build tweaks.
- Reanimation depends on your sandbox reanimation setting being enabled.
- Single-player forcing only supports `*` (no online username offline).

## License

MIT.
