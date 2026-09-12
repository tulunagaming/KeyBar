# KeyBar

A horizontal bar showing, for every dungeon of the current Mythic+ season,
the highest key level you completed there.

* `+15` in level colour — completed in time
* `15` in grey — completed over time
* `--` greyed out icon — not run yet

Your overall Mythic+ score sits on the left. Hovering a dungeon shows the best
timed run, the best overtime run, duration and dungeon score.

Dungeons are sorted by key level, so the gaps in your season are obvious at a
glance.

## Teleports

Clicking a dungeon teleports you there, if you have unlocked the teleport.
A thin blue line under the icon marks the dungeons where that is the case.
Where it is missing, clicking does nothing. The teleport cooldown is shown on
the icon.

Holding shift disables the teleport, so moving the bar can never drop you into
a dungeon by accident.

## Mouse

| Action | Effect |
| --- | --- |
| Left click a dungeon | teleport there |
| **Shift + left click, drag** | move the bar — works anywhere on it |
| **Shift + right click** | open the settings |

Both shift actions are listed in every tooltip, so you do not have to remember
them.

## Settings

Game menu → Interface → AddOns → KeyBar, or shift + right click the bar:

* **Size** — how large the bar is drawn
* **Opacity** — how opaque it is, so it can sit quietly over the game
* **Hide in combat** — the bar disappears during combat and returns afterwards

## Commands

| Command | Effect |
| --- | --- |
| `/keybar` | show / hide the bar |
| `/keybar lock` | lock or unlock the position |
| `/keybar scale 1.2` | set size (0.5 – 3) |
| `/keybar alpha 80` | set opacity in percent (20 – 100) |
| `/keybar sort` | sort by level or by name |
| `/keybar reset` | reset position, size and opacity |

Position, size and all settings are saved per account.

## Languages

English and German. Dungeon names always follow your client language; the
abbreviations stay English, since that is what group finder listings use.
