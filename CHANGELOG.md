# Changelog

## 1.3.2

* Behoben: Nach jedem gewirkten Zauber lief eine kurze Sanduhr ueber alle
  Dungeon-Felder. Das war der globale Cooldown, dem die Teleporte unterliegen.
  Angezeigt wird jetzt nur noch die echte Abklingzeit des Teleports.

## 1.3.1

* Behoben: `ADDON_ACTION_BLOCKED` beim Abschliessen eines Schluessels. Die
  Leiste baute sich mitten im Kampf neu auf und verschob dabei ihre
  geschuetzten Buttons. Aktualisierungen, die im Kampf anfallen, werden jetzt
  vorgemerkt und direkt nach Kampfende nachgeholt.
* Verschieben und Einstellungen oeffnen sind im Kampf gesperrt statt einen
  Fehler auszuloesen. Der Deckkraft-Regler wirkt weiterhin sofort.

## 1.3.0

* **Der Schluessel in deiner Tasche wird angezeigt.** Der Dungeon, fuer den du
  gerade einen Schluessel traegst, bekommt die Stufe als tuerkise Zahl in die
  obere rechte Ecke. Kein eigenes Feld, keine zusaetzliche Zelle -- die Leiste
  bleibt gleich breit.
* Der Tooltip nennt die Stufe und vergleicht sie mit deiner Bestleistung in
  diesem Dungeon: darueber, gleichauf oder darunter.
* Die Anzeige wandert mit, sobald du einen anderen Schluessel bekommst.

## 1.2.6

* Die Schluesselstufe sass direkt auf dem blauen Teleport-Streifen und wurde
  von ihm beruehrt. Sie steht jetzt drei Pixel hoeher.

## 1.2.5

* Die Fusszeile mit Autor und Version stand weiterhin in Ueberschriften-
  Groesse. Die Schrift wird jetzt rekursiv gesucht und zusaetzlich einen
  Frame spaeter nachgesetzt, weil die Vorlage sie vorher wieder ueberschreibt.

## 1.2.4

* Beschreibung auf den aktuellen Stand gebracht: Umschalt-Bedienung,
  Optionsseite, Deckkraft und der Befehl `/keybar alpha` fehlten dort noch.

## 1.2.3

* Autor und Version stehen jetzt als kleine Fusszeile unter den Einstellungen
  statt als Ueberschrift darueber.

## 1.2.2

* Die Optionsseite nennt jetzt Version und Autor. Beides wird aus der .toc
  gelesen, muss also nur an einer Stelle gepflegt werden.

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
