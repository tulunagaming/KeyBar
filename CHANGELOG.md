# Changelog

## 1.2.1

* Behoben: Ueber der Wertungsanzeige links liess sich die Leiste nicht
  verschieben. Dort lag ein eigener Rahmen fuer den Tooltip, der das Ziehen
  nicht weitergereicht hat.

## 1.2.0

* Verschieben jetzt mit **Umschalt + Linksklick** -- auch ueber den Dungeon-
  Feldern, nicht mehr nur auf freier Flaeche. Ein versehentliches Verrutschen
  beim Teleportieren ist damit ausgeschlossen.
* **Umschalt + Rechtsklick** oeffnet die Einstellungen.
* Beide Hinweise stehen jetzt in jedem Tooltip.

## 1.1.0

* Optionsseite unter Spiel -> Interface -> AddOns -> KeyBar
  mit Reglern fuer Groesse und Deckkraft sowie "Im Kampf ausblenden"
* Neuer Befehl `/keybar alpha <20-100>`
* Behoben: Der Teleport-Klick loeste ADDON_ACTION_FORBIDDEN aus
  (CastSpellByID ist fuer Addons gesperrt). Der Button benutzt jetzt
  einen Makrotext mit dem Zaubernamen.

## 1.0.3

Keine Funktionsaenderung. KeyBar erscheint ab jetzt auch auf CurseForge.

## 1.0.2

Keine Funktionsaenderung. Korrektur der Release-Automatik.

## 1.0.1

Keine Funktionsaenderung. Erste ueber den BigWigs-Packager gebaute Version -
ab hier entsteht das Paket automatisch aus dem Repository.

## 1.0.0

Initial release.

* Horizontal bar with one cell per dungeon of the current season
* Best key level per dungeon, coloured by level, timed and overtime separated
* Overall Mythic+ score
* Click to teleport where the teleport is unlocked, with cooldown display
* Tooltip with duration and dungeon score
* Movable, scalable, sortable by level or name
* English and German
