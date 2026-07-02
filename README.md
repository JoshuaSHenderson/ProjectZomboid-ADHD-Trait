# ADHD Trait — Project Zomboid Mod

Adds a new character trait, **ADHD**, that trades raw speed for a lethal
inability to sit still.

- **Everything is faster.** All timed actions (crafting, reading, foraging,
  ripping clothes, disassembling, everything routed through the game's timed
  action system) complete about **3× faster**. You also move faster.
- **Stillness kills.** Stand still too long and your character drops dead — and
  gets back up as a zombie. The idle limit defaults to **15 seconds** and is
  configurable in Sandbox Options. A red **"MOVE!"** countdown warns you for the
  final 5 seconds.
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
| **Seconds standing still before death** (`ADHD.KillSeconds`) | integer, 1–600 | `15` | How many real seconds an ADHD character may stand still before dying and reanimating. The warning countdown shows for the final 5 seconds. |
| **Forced usernames** (`ADHD.ForcedUsernames`) | string | *(empty)* | Comma-separated list of usernames forced to take the ADHD trait at creation. `*` forces everyone. Empty means the trait is simply optional. |

### Forcing the trait

Set **Forced usernames** to force the trait on matching players:

```
ADHD.ForcedUsernames = "Alice,Bob"    -- only Alice and Bob
ADHD.ForcedUsernames = "*"            -- everyone
ADHD.ForcedUsernames = ""             -- nobody; trait is optional
```

For matched players the trait is added and locked in the creation screen, with a
guaranteed backstop that re-applies it when the character spawns even if the
creation UI differs between builds.

> **Single-player note:** username matching relies on the online username, which
> doesn't exist in single-player, so only `*` takes effect offline. In
> multiplayer, exact names and `*` both work.

---

## Installation

### From a local copy

Copy the `ADHD` folder into your Zomboid mods directory:

```
%USERPROFILE%\Zomboid\mods\ADHD\
```

Then enable **ADHD** in the in-game Mods menu, and add it to your server's
`Mods=` line for multiplayer.

### Folder layout

The mod ships both build layouts in one package:

```
ADHD/
├── mod.info                       # Build 41 manifest
├── media/                         # Build 41 content
│   ├── sandbox-options.txt
│   └── lua/
│       ├── shared/Translate/EN/   # trait + sandbox strings
│       └── client/ADHD/           # trait logic (5 files)
└── 42/
    ├── mod.info                   # Build 42 manifest
    └── media/                     # Build 42 content (mirror of the above)
```

Build 42 automatically reads the `42/` subfolder; Build 41 reads the root.

---

## How it works (files)

| File | Responsibility |
|---|---|
| `ADHD_Trait.lua` | Registers the trait (cost 0) with Fitness/Sprinting/Nimble XP boosts — these perk levels are the guaranteed movement-speed buff via the game's own speed formulas. |
| `ADHD_ActionSpeed.lua` | Wraps `ISBaseTimedAction:adjustMaxTime` to divide every timed action's duration by 3 (skips indefinite actions). |
| `ADHD_MoveSpeed.lua` | Best-effort direct `setRunSpeedModifier` bump, guarded so it's harmless if a build lacks the API. |
| `ADHD_IdleDeath.lua` | The idle timer: reads `ADHD.KillSeconds`, tracks activity, shows the warning, and zombifies on timeout. |
| `ADHD_ForceTrait.lua` | Reads `ADHD.ForcedUsernames`; locks the trait in the creation screen and enforces it on spawn. |

---

## Known limitations

- Not yet verified in-game on either build; treat as beta. Creation-UI internals
  and the direct speed-modifier API may need per-build tweaks.
- Reanimation depends on your sandbox reanimation setting being enabled.
- Single-player forcing only supports `*` (no online username offline).

## License

MIT.
