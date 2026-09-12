-------------------------------------------------------------------------------
-- Optionsseite unter Spiel -> Interface -> AddOns -> KeyBar.
--
-- Die Werte werden direkt in KeyBarDB geschrieben; nach jeder Aenderung wendet
-- ns.ApplySettings() sie auf die Leiste an.
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

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
    L["Version %s by %s"]            = "Version %s von %s"
    L["Version %s"]                  = "Version %s"
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

    local function AddHeader(text)
        if layout and layout.AddInitializer and CreateSettingsListSectionHeaderInitializer then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
        end
    end

    local version, author = Meta("Version"), Meta("Author")
    if version and author then
        AddHeader(string.format(L["Version %s by %s"], version, author))
    elseif version then
        AddHeader(string.format(L["Version %s"], version))
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

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end
