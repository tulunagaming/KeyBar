-------------------------------------------------------------------------------
-- Optionsseite unter Spiel -> Interface -> AddOns -> KeyBar.
--
-- Die Werte werden direkt in KeyBarDB geschrieben; nach jeder Aenderung wendet
-- ns.ApplySettings() sie auf die Leiste an.
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-- Charakter und Realm des Autors.
local AUTHOR = "Tuluna-Antonidas"

-- Dieselbe Uebersetzungstabelle wie in KeyBar.lua: Schluessel ist der
-- englische Text, fehlende Schluessel fallen auf sich selbst zurueck.
local L = setmetatable({}, { __index = function(_, key) return key end })

if GetLocale() == "deDE" then
    L["Size"]                        = "Groesse"
    L["How large the bar is drawn."] = "Wie gross die Leiste gezeichnet wird."
    L["Opacity"]                     = "Deckkraft"
    L["How opaque the bar is. Lower values let the game show through."] =
        "Wie deckend die Leiste ist. Niedrigere Werte lassen das Spiel durchscheinen."
    L["Hide in combat"]              = "Im Kampf ausblenden"
    L["When enabled the bar disappears while you are in combat and comes back afterwards."] =
        "Blendet die Leiste im Kampf aus und danach wieder ein."
    L["Created by %s"]               = "Erstellt von %s"
end

local function Apply()
    if ns.ApplySettings then ns.ApplySettings() end
end

function ns.SetupOptions()
    -- Ohne die moderne Settings-API (sehr alte Clients) bleibt es bei den
    -- Slash-Befehlen; das Addon soll deswegen nicht scheitern.
    if not (Settings and Settings.RegisterVerticalLayoutCategory
            and Settings.RegisterAddOnSetting and Settings.RegisterAddOnCategory) then
        return
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("KeyBar")

    -- Autor und Version aus der .toc, damit beides nur an einer Stelle
    -- gepflegt werden muss.
    local function Meta(field)
        if C_AddOns and C_AddOns.GetAddOnMetadata then
            return C_AddOns.GetAddOnMetadata(ADDON_NAME, field)
        end
        return nil
    end

    -- Kleine Fusszeile. Die Kopfzeilen-Vorlage ist die einzige, die ohne
    -- eigenes XML auskommt; ihre Schrift wird nachtraeglich verkleinert,
    -- damit die Zeilen nicht groesser wirken als die Einstellungstexte.
    local function AddFootnote(text)
        if not (layout and layout.AddInitializer
                and CreateSettingsListSectionHeaderInitializer) then
            return
        end
        local init = CreateSettingsListSectionHeaderInitializer(text)
        if init.AddInitializer then
            init:AddInitializer(function(frame)
                local label = frame.Title
                if not label then
                    for _, region in ipairs({ frame:GetRegions() }) do
                        if region:GetObjectType() == "FontString" then
                            label = region
                            break
                        end
                    end
                end
                if label then
                    label:SetFontObject(GameFontDisableSmall)
                end
            end)
        end
        layout:AddInitializer(init)
    end

    -- --- Groesse ------------------------------------------------------------
    local scale = Settings.RegisterAddOnSetting(
        category, "KEYBAR_SCALE", "scale", KeyBarDB,
        Settings.VarType.Number, L["Size"], 1.1)

    local scaleOptions = Settings.CreateSliderOptions(0.5, 3.0, 0.05)
    if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
        scaleOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value) return string.format("%.0f%%", value * 100) end)
    end
    Settings.CreateSlider(category, scale, scaleOptions,
        L["How large the bar is drawn."])
    Settings.SetOnValueChangedCallback("KEYBAR_SCALE", Apply)

    -- --- Deckkraft ----------------------------------------------------------
    -- Untergrenze 0.2 statt 0: eine voellig unsichtbare Leiste waere nicht
    -- mehr zu finden, und zum Ausblenden gibt es die anderen Schalter.
    local alpha = Settings.RegisterAddOnSetting(
        category, "KEYBAR_ALPHA", "alpha", KeyBarDB,
        Settings.VarType.Number, L["Opacity"], 1.0)

    local alphaOptions = Settings.CreateSliderOptions(0.2, 1.0, 0.05)
    if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
        alphaOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value) return string.format("%.0f%%", value * 100) end)
    end
    Settings.CreateSlider(category, alpha, alphaOptions,
        L["How opaque the bar is. Lower values let the game show through."])
    Settings.SetOnValueChangedCallback("KEYBAR_ALPHA", Apply)

    -- --- Im Kampf ausblenden ------------------------------------------------
    local hideInCombat = Settings.RegisterAddOnSetting(
        category, "KEYBAR_HIDE_IN_COMBAT", "hideInCombat", KeyBarDB,
        Settings.VarType.Boolean, L["Hide in combat"], false)

    Settings.CreateCheckbox(category, hideInCombat,
        L["When enabled the bar disappears while you are in combat and comes back afterwards."])
    Settings.SetOnValueChangedCallback("KEYBAR_HIDE_IN_COMBAT", Apply)

    -- --- Fusszeile ---------------------------------------------------------
    AddFootnote(string.format(L["Created by %s"], AUTHOR))
    local version = Meta("Version")
    if version then
        AddFootnote(string.format(L["Vers. %s"], version))
    end

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end
