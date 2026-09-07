# KeyBar

A horizontal bar showing, for every dungeon of the current Mythic+ season,
the highest key level you completed there.

* `+15` in level colour - completed in time
* `15` in grey - completed over time
* `--` greyed out icon - not run yet

Your overall Mythic+ score sits on the left. Hovering a dungeon shows best
timed run, best overtime run, duration and score.

## Teleports

Clicking a dungeon teleports you there if you have unlocked the teleport.
A thin blue line under the icon marks the dungeons where that is the case.
Where it is missing, clicking does nothing. The cooldown is shown on the icon.

## Commands

| Command | Effect |
| --- | --- |
| `/keybar` | show / hide the bar |
| `/keybar lock` | lock or unlock the position |
| `/keybar scale 1.2` | set size (0.5 - 3) |
| `/keybar sort` | sort by level or by name |
| `/keybar reset` | reset position and size |

Drag with the left mouse button to move it.

## Languages

English and German. The bar itself uses English dungeon abbreviations in
every language, since that is what group finder listings use.
