-------------------------------------------------------------------------------
-- KeyBar
--
-- Eine horizontale Leiste: pro Dungeon der aktuellen Mythic+ Saison ein Feld
-- mit der hoechsten Schluesselstufe, die dort abgeschlossen wurde.
--
--   +15  = im Zeitlimit  (Farbe nach Stufe)
--    15  = ueber der Zeit (grau)
--    --  = noch nicht gelaufen
--
-- Klick auf ein Feld teleportiert zum Dungeon, sofern der Teleport gelernt
-- ist. Ein blauer Streifen am unteren Rand zeigt, wo das der Fall ist; bei
-- allen anderen passiert beim Klick nichts.
--
-- /keybar        Leiste ein-/ausblenden
-- /keybar lock   Position sperren / entsperren
-- /keybar scale  Groesse (z. B. /keybar scale 1.2)
-- /keybar sort   Sortierung umschalten (Stufe <-> Name)
-- /keybar reset  Position und Groesse zuruecksetzen
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Localization. Keys are the English strings; missing keys fall back to the
-- key itself, so English needs no table of its own.
-------------------------------------------------------------------------------
local L = setmetatable({}, { __index = function(_, key) return key end })

if GetLocale() == "deDE" then
    L["Not run this season."]            = "Diese Saison noch nicht gelaufen."
    L["Timed: +%d"]                      = "Im Zeitlimit: +%d"
    L["Over time: %d"]                   = "Ueber der Zeit: %d"
    L["Score"]                           = "Wertung"
    L["This dungeon has no teleport."]   = "Fuer diesen Dungeon gibt es keinen Teleport."
    L["Click to teleport."]              = "Klick: hinteleportieren."
    L["Teleport not unlocked yet."]      = "Teleport noch nicht freigeschaltet."
    L["Time the dungeon on level 10 to earn it."] =
        "Dafuer den Dungeon auf Stufe 10 im Zeitlimit abschliessen."
    L["Mythic+ score for this season."]  = "Mythic+ Gesamtwertung dieser Saison."
    L["Drag to move."]                   = "Ziehen zum Verschieben."
    L["/keybar for more options."]       = "/keybar fuer weitere Optionen."
    L["hidden."]                         = "ausgeblendet."
    L["shown."]                          = "eingeblendet."
    L["position locked."]                = "Position gesperrt."
    L["position unlocked."]              = "Position entsperrt."
    L["scale set to %.2f."]              = "Groesse auf %.2f gesetzt."
    L["Please give a value between 0.5 and 3, e.g. /keybar scale 1.2"] =
        "Bitte einen Wert zwischen 0.5 und 3 angeben, z. B. /keybar scale 1.2"
    L["sorting: by level."]              = "Sortierung: nach Stufe."
    L["sorting: by name."]               = "Sortierung: nach Name."
    L["reset."]                          = "zurueckgesetzt."
    L["Commands: /keybar | lock | scale <number> | alpha <number> | sort | reset"] =
        "Befehle: /keybar | lock | scale <Zahl> | alpha <Zahl> | sort | reset"
    L["opacity set to %d%%."]            = "Deckkraft auf %d%% gesetzt."
    L["Please give a value between 20 and 100, e.g. /keybar alpha 80"] =
        "Bitte einen Wert zwischen 20 und 100 angeben, z. B. /keybar alpha 80"
    L["Size"]                            = "Groesse"
    L["How large the bar is drawn."]     = "Wie gross die Leiste gezeichnet wird."
    L["Opacity"]                         = "Deckkraft"
    L["How opaque the bar is. Lower values let the game show through."] =
        "Wie deckend die Leiste ist. Niedrigere Werte lassen das Spiel durchscheinen."
    L["Hide in combat"]                  = "Im Kampf ausblenden"
    L["When enabled the bar disappears while you are in combat and comes back afterwards."] =
        "Blendet die Leiste im Kampf aus und danach wieder ein"
end

local CELL_SIZE     = 42
local CELL_GAP      = 4
local PADDING       = 8
local HEADER_WIDTH  = 46

-------------------------------------------------------------------------------
-- Englische Dungeon-Kuerzel, geschluesselt nach ChallengeMode-Map-ID.
-- Die ID ist sprachunabhaengig, das Kuerzel bleibt also auch im deutschen
-- Client korrekt. Unbekannte Dungeons bekommen automatisch Initialen aus
-- ihrem Namen.
-------------------------------------------------------------------------------
local SHORT_NAMES = {
    [161] = "SR",     -- Skyreach
    [239] = "SEAT",   -- Seat of the Triumvirate
    [249] = "KR",     -- Kings' Rest
    [250] = "TOS",    -- Temple of Sethraliss
    [399] = "RLP",    -- Ruby Life Pools
    [402] = "AA",     -- Algeth'ar Academy
    [556] = "POS",    -- Pit of Saron
    [557] = "WS",     -- Windrunner Spire
    [558] = "MT",     -- Magisters' Terrace
    [559] = "NPX",    -- Nexus-Point Xenas
    [560] = "MC",     -- Maisara Caverns
    [584] = "BV",     -- The Blinding Vale
    [585] = "VSA",    -- Voidscar Arena
    [586] = "DON",    -- Den of Nalorakk
    [587] = "MR",     -- Murder Row
    [588] = "AOF",    -- Altar of Fangs
}

-------------------------------------------------------------------------------
-- Teleport-Zauber je ChallengeMode-Map-ID. Wer den Zauber nicht gelernt hat
-- (Dungeon noch nicht rechtzeitig auf +10 abgeschlossen), bei dem passiert
-- beim Klick schlicht nichts.
-------------------------------------------------------------------------------
local TELEPORTS = {
    [249] = 1286831,   -- Kings' Rest
    [250] = 1286828,   -- Temple of Sethraliss
    [399] = 393256,    -- Ruby Life Pools
    [584] = 1286801,   -- The Blinding Vale
    [585] = 1286804,   -- Voidscar Arena
    [586] = 1286807,   -- Den of Nalorakk
    [587] = 1286809,   -- Murder Row
    [588] = 1286812,   -- Altar of Fangs
}

-- Zaubername statt ID: ein sicherer Button mit numerischem "spell"-Attribut
-- laesst Blizzards Vorlage CastSpellByID() aufrufen, und das ist fuer Addons
-- gesperrt (ADDON_ACTION_FORBIDDEN). Ueber /cast <Name> geht es sauber.
local function SpellName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    end
    return nil
end

local function TeleportKnown(spellID)
    if not spellID then return false end
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    return false
end

-- Fallback fuer Dungeons, die noch nicht in der Tabelle stehen: Anfangs-
-- buchstaben der Woerter, Fuellwoerter uebersprungen.
local IGNORED_WORDS = {
    ["der"] = true, ["die"] = true, ["das"] = true, ["den"] = true,
    ["des"] = true, ["dem"] = true, ["von"] = true, ["vom"] = true,
    ["the"] = true, ["of"] = true,  ["and"] = true, ["und"] = true,
}

local function DeriveShortName(name)
    if not name or name == "" then return "??" end

    local letters, firstWord = {}, nil
    for word in name:gmatch("[^%s%-]+") do
        if not IGNORED_WORDS[word:lower()] then
            firstWord = firstWord or word
            letters[#letters + 1] = word:sub(1, 1):upper()
        end
    end

    -- Bei mehreren Woertern die Initialen. Bei einem einzigen Wort waere das
    -- nur ein Buchstabe, deshalb dort die ersten drei Buchstaben.
    if #letters >= 2 then
        return table.concat(letters, "", 1, math.min(#letters, 4))
    end

    local source = firstWord or name
    local short = ""
    -- Bewusst [A-Za-z] statt %a: so koennen keine halben Umlaut-Bytes in das
    -- Kuerzel geraten, was sonst kaputte Zeichen im Spiel ergibt.
    for letter in source:gmatch("[A-Za-z]") do
        short = short .. letter
        if #short == 3 then break end
    end
    return (short ~= "" and short or name:sub(1, 2)):upper()
end

local function ShortNameFor(mapID, name)
    return SHORT_NAMES[mapID] or DeriveShortName(name)
end

local DEFAULTS = {
    point   = "CENTER",
    x       = 0,
    y       = 220,
    scale   = 1.1,
    alpha   = 1.0,
    locked  = false,
    hidden  = false,
    hideInCombat = false,
    sort    = "level",   -- "level" oder "name"
}

local cells = {}
local bar

-------------------------------------------------------------------------------
-- Hilfsfunktionen
-------------------------------------------------------------------------------

local function db()
    KeyBarDB = KeyBarDB or {}
    for key, value in pairs(DEFAULTS) do
        if KeyBarDB[key] == nil then
            KeyBarDB[key] = value
        end
    end
    return KeyBarDB
end

-- Farbe einer Schluesselstufe. Blizzard liefert die Abstufung selbst mit;
-- der Fallback deckt aeltere Clients ab, falls die API mal fehlt.
local function LevelColor(level)
    if C_ChallengeMode and C_ChallengeMode.GetKeystoneLevelRarityColor then
        local color = C_ChallengeMode.GetKeystoneLevelRarityColor(level)
        if color then return color.r, color.g, color.b end
    end
    if level >= 15 then return 1.00, 0.50, 0.00 end
    if level >= 12 then return 0.64, 0.21, 0.93 end
    if level >= 10 then return 0.00, 0.44, 0.87 end
    if level >= 5  then return 0.12, 1.00, 0.00 end
    return 1.00, 1.00, 1.00
end

local function ScoreColor(score)
    if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
        local color = C_ChallengeMode.GetDungeonScoreRarityColor(score)
        if color then return color.r, color.g, color.b end
    end
    return 1, 1, 1
end

local function FormatDuration(value)
    if not value or value <= 0 then return nil end
    -- Je nach Quelle kommen Sekunden oder Millisekunden an. Ein Dungeonlauf
    -- dauert nie 20000 Sekunden, also ist alles darueber sicher in ms.
    local seconds = (value > 20000) and (value / 1000) or value
    seconds = math.floor(seconds + 0.5)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-------------------------------------------------------------------------------
-- Daten einsammeln
-------------------------------------------------------------------------------

-- Liefert eine Liste: { mapID, name, texture, best (Stufe), timed (bool),
--                       score, duration }
local function CollectRuns()
    local maps = C_ChallengeMode.GetMapTable()
    if not maps or #maps == 0 then return nil end

    local list = {}
    for _, mapID in ipairs(maps) do
        local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
        local intime, overtime = C_MythicPlus.GetSeasonBestForMap(mapID)

        local entry = {
            mapID    = mapID,
            name     = name or ("Dungeon " .. mapID),
            short    = ShortNameFor(mapID, name),
            texture  = texture,
            best     = 0,
            timed    = false,
            score    = 0,
            duration = nil,
            intime   = intime,
            overtime = overtime,
        }

        -- Der bessere der beiden Laeufe bestimmt die Anzeige. Ein Lauf im
        -- Zeitlimit gewinnt bei gleicher Stufe gegen einen ueber der Zeit.
        if intime and intime.level and intime.level > 0 then
            entry.best     = intime.level
            entry.timed    = true
            entry.score    = intime.dungeonScore or 0
            entry.duration = intime.durationSec
        end
        if overtime and overtime.level and overtime.level > entry.best then
            entry.best     = overtime.level
            entry.timed    = false
            entry.score    = overtime.dungeonScore or 0
            entry.duration = overtime.durationSec
        end

        list[#list + 1] = entry
    end

    if db().sort == "name" then
        table.sort(list, function(a, b) return a.name < b.name end)
    else
        table.sort(list, function(a, b)
            if a.best ~= b.best then return a.best > b.best end
            return a.name < b.name
        end)
    end

    return list
end

-------------------------------------------------------------------------------
-- Tooltip
-------------------------------------------------------------------------------

local function AddTeleportLine(entry)
    GameTooltip:AddLine(" ")
    if not TELEPORTS[entry.mapID] then
        GameTooltip:AddLine(L["This dungeon has no teleport."], 0.5, 0.5, 0.5)
    elseif entry.known then
        GameTooltip:AddLine(L["Click to teleport."], 0.2, 0.9, 1.0)
    else
        GameTooltip:AddLine(L["Teleport not unlocked yet."], 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["Time the dungeon on level 10 to earn it."], 0.5, 0.5, 0.5)
    end
end

-- Der Tooltip haengt bewusst an der gesamten Leiste, nicht an der einzelnen
-- Zelle. An der Zelle wuerde er sie ueberdecken; das loest sofort OnLeave aus,
-- der Tooltip verschwindet, OnEnter feuert erneut -- ein Flackern, in dem
-- kein Klick durchkommt. Ober- oder unterhalb je nachdem, wo mehr Platz ist.
local TOOLTIP_GAP = 10

local function AnchorTooltip(cell)
    GameTooltip:SetOwner(cell, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()

    local _, centerY = bar:GetCenter()
    local screenHeight = UIParent:GetHeight() or 0

    if centerY and screenHeight > 0 and centerY > screenHeight / 2 then
        GameTooltip:SetPoint("TOP", bar, "BOTTOM", 0, -TOOLTIP_GAP)
    else
        GameTooltip:SetPoint("BOTTOM", bar, "TOP", 0, TOOLTIP_GAP)
    end
end

local function ShowCellTooltip(cell)
    local entry = cell.entry
    if not entry then return end

    AnchorTooltip(cell)
    GameTooltip:AddDoubleLine(entry.name, entry.short, 1, 0.82, 0, 0.6, 0.6, 0.6)

    if entry.best == 0 then
        GameTooltip:AddLine(L["Not run this season."], 0.7, 0.7, 0.7)
        AddTeleportLine(entry)
        GameTooltip:Show()
        return
    end

    local intime, overtime = entry.intime, entry.overtime

    if intime and intime.level and intime.level > 0 then
        local r, g, b = LevelColor(intime.level)
        local right = FormatDuration(intime.durationSec)
        GameTooltip:AddDoubleLine(
            string.format(L["Timed: +%d"], intime.level),
            right or "",
            r, g, b, 0.8, 0.8, 0.8)
    end

    if overtime and overtime.level and overtime.level > 0 then
        local right = FormatDuration(overtime.durationSec)
        GameTooltip:AddDoubleLine(
            string.format(L["Over time: %d"], overtime.level),
            right or "",
            0.65, 0.65, 0.65, 0.8, 0.8, 0.8)
    end

    if entry.score and entry.score > 0 then
        local r, g, b = ScoreColor(entry.score)
        GameTooltip:AddDoubleLine(L["Score"], string.format("%.1f", entry.score),
            0.7, 0.7, 0.7, r, g, b)
    end

    AddTeleportLine(entry)
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- Aufbau der Leiste
-------------------------------------------------------------------------------

local function CreateCell(index)
    -- SecureActionButtonTemplate: das Wirken eines Zaubers ist geschuetzt und
    -- geht nur ueber einen sicheren Button, nicht per OnClick-Skript.
    local cell = CreateFrame("Button", "KeyBarCell" .. index, bar,
                             "SecureActionButtonTemplate")
    cell:SetSize(CELL_SIZE, CELL_SIZE)
    -- Beide Varianten, damit der Klick unabhaengig von der Einstellung
    -- "Aktion bei Tastendruck ausloesen" ankommt.
    cell:RegisterForClicks("AnyUp", "AnyDown")

    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetAllPoints()
    cell.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    cell.cooldown = CreateFrame("Cooldown", nil, cell, "CooldownFrameTemplate")
    cell.cooldown:SetAllPoints()
    cell.cooldown:SetDrawEdge(false)

    -- Duenner Streifen am unteren Rand: Teleport ist freigeschaltet.
    cell.portMark = cell:CreateTexture(nil, "OVERLAY", nil, 2)
    cell.portMark:SetPoint("BOTTOMLEFT", 1, 0)
    cell.portMark:SetPoint("BOTTOMRIGHT", -1, 0)
    cell.portMark:SetHeight(2)
    cell.portMark:SetColorTexture(0.2, 0.9, 1.0, 0.9)
    cell.portMark:Hide()

    -- Kuerzel oben, Stufe unten: beide auf einem abgedunkelten Streifen,
    -- damit sie auf jedem Dungeon-Icon lesbar bleiben.
    cell.topShade = cell:CreateTexture(nil, "OVERLAY", nil, 1)
    cell.topShade:SetPoint("TOPLEFT")
    cell.topShade:SetPoint("TOPRIGHT")
    cell.topShade:SetHeight(13)
    cell.topShade:SetColorTexture(0, 0, 0, 0.7)

    cell.short = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
    cell.short:SetPoint("TOPLEFT", 1, -1)
    cell.short:SetPoint("TOPRIGHT", -1, -1)
    cell.short:SetJustifyH("CENTER")

    cell.shade = cell:CreateTexture(nil, "OVERLAY", nil, 1)
    cell.shade:SetPoint("BOTTOMLEFT")
    cell.shade:SetPoint("BOTTOMRIGHT")
    cell.shade:SetHeight(15)
    cell.shade:SetColorTexture(0, 0, 0, 0.7)

    cell.level = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cell.level:SetPoint("BOTTOM", 0, 1)

    cell:SetScript("OnEnter", ShowCellTooltip)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)

    cells[index] = cell
    return cell
end

-- Verknuepft eine Zelle mit ihrem Teleport-Zauber. Im Kampf sind Aenderungen
-- an sicheren Buttons gesperrt; dann merken wir uns das und holen es nach,
-- sobald der Kampf vorbei ist.
local pendingSecureUpdate = false

local function ApplyTeleport(cell)
    local entry = cell.entry
    if not entry then return end

    local spellID = TELEPORTS[entry.mapID]
    entry.spellID = spellID
    entry.known   = TeleportKnown(spellID)

    local name = entry.known and SpellName(spellID) or nil

    if InCombatLockdown() then
        pendingSecureUpdate = true
    elseif name then
        cell:SetAttribute("type", "macro")
        cell:SetAttribute("macrotext", "/cast " .. name)
    else
        -- Auch den Namen koennen wir kurz nach dem Login noch nicht kennen;
        -- dann bleibt der Button vorerst ohne Aktion und SPELLS_CHANGED
        -- traegt ihn nach.
        cell:SetAttribute("type", nil)
        cell:SetAttribute("macrotext", nil)
        cell:SetAttribute("spell", nil)
    end

    cell.portMark:SetShown(entry.known)

    if entry.known and C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info and info.startTime and info.duration and info.duration > 0 then
            cell.cooldown:SetCooldown(info.startTime, info.duration)
        else
            cell.cooldown:SetCooldown(0, 0)
        end
    else
        cell.cooldown:SetCooldown(0, 0)
    end
end

local function UpdateAllTeleports()
    for _, cell in ipairs(cells) do
        if cell:IsShown() then ApplyTeleport(cell) end
    end
end

local function Layout(count)
    -- Drei Polster: links vom Score, zwischen Score und erster Zelle, und
    -- rechts hinter der letzten Zelle. Mit nur zweien sass die letzte Zelle
    -- am Rand fest und das Bild wirkte unsymmetrisch.
    local width = PADDING * 3 + HEADER_WIDTH
                  + count * CELL_SIZE + math.max(0, count - 1) * CELL_GAP
    bar:SetSize(width, CELL_SIZE + PADDING * 2)
end

local function Refresh()
    if not bar then return end

    local list = CollectRuns()
    if not list then
        -- Kartendaten sind noch nicht da; das Event weckt uns gleich wieder.
        C_MythicPlus.RequestMapInfo()
        return
    end

    local score = C_ChallengeMode.GetOverallDungeonScore() or 0
    local r, g, b = ScoreColor(score)
    bar.score:SetText(score > 0 and string.format("%d", score) or "--")
    bar.score:SetTextColor(r, g, b)

    for index, entry in ipairs(list) do
        local cell = cells[index] or CreateCell(index)
        cell.entry = entry

        cell:ClearAllPoints()
        if index == 1 then
            -- Bewusst am Rahmen selbst verankert, nicht an bar.score: sichere
            -- Buttons duerfen nicht an Regionen (FontStrings, Texturen) haengen.
            cell:SetPoint("LEFT", bar, "LEFT", PADDING * 2 + HEADER_WIDTH, 0)
        else
            cell:SetPoint("LEFT", cells[index - 1], "RIGHT", CELL_GAP, 0)
        end

        cell.icon:SetTexture(entry.texture or 134400)
        cell.short:SetText(entry.short)

        if entry.best > 0 then
            local lr, lg, lb = LevelColor(entry.best)
            cell.icon:SetDesaturated(false)
            cell.icon:SetVertexColor(1, 1, 1)
            cell.short:SetTextColor(1, 1, 1)
            if entry.timed then
                cell.level:SetText("+" .. entry.best)
                cell.level:SetTextColor(lr, lg, lb)
            else
                cell.level:SetText(tostring(entry.best))
                cell.level:SetTextColor(0.65, 0.65, 0.65)
            end
        else
            cell.icon:SetDesaturated(true)
            cell.icon:SetVertexColor(0.5, 0.5, 0.5)
            cell.short:SetTextColor(0.6, 0.6, 0.6)
            cell.level:SetText("--")
            cell.level:SetTextColor(0.5, 0.5, 0.5)
        end

        ApplyTeleport(cell)
        cell:Show()
    end

    for index = #list + 1, #cells do
        cells[index]:Hide()
    end

    Layout(#list)
end

-- Sichtbarkeit. Die Zellen sind geschuetzte Buttons; sie im Kampf einfach zu
-- verstecken waere eine gesperrte Aktion. Deshalb uebernimmt das der sichere
-- State-Driver von Blizzard, der genau dafuer gedacht ist.
local pendingVisibility = false

local function ApplyVisibility()
    local settings = db()

    if InCombatLockdown() then
        pendingVisibility = true
        return
    end
    pendingVisibility = false

    UnregisterStateDriver(bar, "visibility")
    if settings.hidden then
        bar:Hide()
    elseif settings.hideInCombat then
        RegisterStateDriver(bar, "visibility", "[combat] hide; show")
    else
        bar:Show()
    end
end

local function ApplySettings()
    local settings = db()
    bar:SetScale(settings.scale)
    bar:SetAlpha(settings.alpha)
    bar:ClearAllPoints()
    bar:SetPoint(settings.point, UIParent, settings.point, settings.x, settings.y)
    bar:EnableMouse(not settings.locked)
    bar:SetMovable(not settings.locked)
    ApplyVisibility()
end

-- Damit die Optionsseite nach jeder Aenderung dasselbe anwenden kann.
ns.ApplySettings = function() if bar then ApplySettings() end end

local function CreateBar()
    bar = CreateFrame("Frame", "KeyBarFrame", UIParent, "BackdropTemplate")
    bar:SetSize(200, CELL_SIZE + PADDING * 2)
    bar:SetClampedToScreen(true)
    bar:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    bar:SetBackdropColor(0, 0, 0, 0.6)
    bar:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.8)

    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not db().locked then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        local settings = db()
        settings.point, settings.x, settings.y = point, x, y
    end)

    bar.score = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bar.score:SetPoint("LEFT", bar, "LEFT", PADDING, 0)
    bar.score:SetWidth(HEADER_WIDTH)
    bar.score:SetJustifyH("CENTER")

    bar.scoreHover = CreateFrame("Frame", nil, bar)
    bar.scoreHover:SetAllPoints(bar.score)
    bar.scoreHover:SetScript("OnEnter", function(self)
        AnchorTooltip(self)
        GameTooltip:AddLine("KeyBar", 1, 0.82, 0)
        GameTooltip:AddLine(L["Mythic+ score for this season."], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Drag to move."], 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["/keybar for more options."], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    bar.scoreHover:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-------------------------------------------------------------------------------
-- Slash-Befehle
-------------------------------------------------------------------------------

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99KeyBar|r: " .. msg)
end

SLASH_KEYBAR1 = "/keybar"
SlashCmdList["KEYBAR"] = function(input)
    local settings = db()
    local command, argument = strsplit(" ", strtrim(input or ""), 2)
    command = (command or ""):lower()

    if command == "" then
        settings.hidden = not settings.hidden
        ApplySettings()
        Print(settings.hidden and L["hidden."] or L["shown."])

    elseif command == "lock" then
        settings.locked = not settings.locked
        ApplySettings()
        Print(settings.locked and L["position locked."] or L["position unlocked."])

    elseif command == "scale" then
        local value = tonumber(argument)
        if value and value >= 0.5 and value <= 3 then
            settings.scale = value
            ApplySettings()
            Print(string.format(L["scale set to %.2f."], value))
        else
            Print(L["Please give a value between 0.5 and 3, e.g. /keybar scale 1.2"])
        end

    elseif command == "alpha" then
        local value = tonumber(argument)
        if value and value >= 20 and value <= 100 then
            settings.alpha = value / 100
            ApplySettings()
            Print(string.format(L["opacity set to %d%%."], value))
        else
            Print(L["Please give a value between 20 and 100, e.g. /keybar alpha 80"])
        end

    elseif command == "sort" then
        settings.sort = (settings.sort == "level") and "name" or "level"
        Refresh()
        Print(settings.sort == "level" and L["sorting: by level."] or L["sorting: by name."])

    elseif command == "reset" then
        settings.point, settings.x, settings.y = DEFAULTS.point, DEFAULTS.x, DEFAULTS.y
        settings.scale, settings.locked, settings.hidden = DEFAULTS.scale, false, false
        settings.alpha, settings.hideInCombat = DEFAULTS.alpha, DEFAULTS.hideInCombat
        ApplySettings()
        Print(L["reset."])

    else
        Print(L["Commands: /keybar | lock | scale <number> | alpha <number> | sort | reset"])
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
events:RegisterEvent("CHALLENGE_MODE_COMPLETED")
events:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "SPELLS_CHANGED" or event == "SPELL_UPDATE_COOLDOWN" then
        -- Nur Zauberstatus und Abklingzeit, nicht die ganze Leiste neu bauen.
        if bar then UpdateAllTeleports() end
        return

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Im Kampf blockierte Attribut-Aenderungen jetzt nachholen.
        if bar and pendingSecureUpdate then
            pendingSecureUpdate = false
            UpdateAllTeleports()
        end
        if bar and pendingVisibility then ApplyVisibility() end
        return

    elseif event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        db()
        CreateBar()
        ApplySettings()
        if ns.SetupOptions then ns.SetupOptions() end

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_MythicPlus.RequestMapInfo()
        C_MythicPlus.RequestCurrentAffixes()
        C_Timer.After(2, Refresh)

    else
        -- Nach einem abgeschlossenen Lauf braucht der Server einen Moment,
        -- bis die neue Bestleistung abrufbar ist.
        C_Timer.After(2, Refresh)
    end
end)
