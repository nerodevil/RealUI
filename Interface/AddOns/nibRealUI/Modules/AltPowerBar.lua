local _, private = ...

-- RealUI --
local RealUI = private.RealUI
local db

local MODNAME = "AltPowerBar"
local AltPowerBar = RealUI:NewModule(MODNAME, "AceEvent-3.0")

local LoggedIn = false
local APBFrames = {}
local UpdateInterval = 0

--[[ Testing spots:
    ALT_POWER_TYPE_HORIZONTAL:
        Draenor, SMV: Akeeta's Hovel > Pillars of Fate -- click portal
        EK, Hillsbrad: Quest > Peacebloom vs. Scourge -- uses vehicle
        ToT, Lei Shen: Uses the bar on boss units

    ALT_POWER_TYPE_CIRCULAR:
        BWD, Atramedes:

    ALT_POWER_TYPE_COUNTER:
        Darkmoon Fair: Tonk Commander -- Uses vehicle with both HORIZONTAL and COUNTER
            see also: https://github.com/oUF-wow/oUF/issues/293


]]
-- Events
function AltPowerBar:PowerUpdate()
    if _G.UnitAlternatePowerInfo("player") then
        APBFrames.bg:Show()
        APBFrames.bar:Show()
    else
        APBFrames.bg:Hide()
        APBFrames.bar:Hide()
    end
end

-- Colors
function AltPowerBar:UpdateColors()
    -- Bar
    local color = RealUI.media.colors.green
    APBFrames.bar:SetStatusBarColor(color[1], color[2], color[3], 0.85)
end

-- Position
function AltPowerBar:UpdatePosition()
    -- BG + Border
    APBFrames.bg:SetPoint(db.position.anchorfrom, _G.UIParent, db.position.anchorto, db.position.x, db.position.y)

    APBFrames.bg:SetFrameStrata("MEDIUM")
    APBFrames.bg:SetFrameLevel(1)

    APBFrames.bg:SetHeight(db.size.height)
    APBFrames.bg:SetWidth(db.size.width)
end

-- Refresh
function AltPowerBar:RefreshMod()
    if not RealUI:GetModuleEnabled(MODNAME) then return end

    db = self.db.profile

    AltPowerBar:UpdatePosition()
    AltPowerBar:UpdateColors()
end

function AltPowerBar:PLAYER_LOGIN()
    LoggedIn = true
    AltPowerBar:RefreshMod()
    AltPowerBar:PowerUpdate()
end

-- Create Frames
function AltPowerBar:CreateFrames()
    APBFrames = {
        bg = nil,
        bar = nil,
        text = nil,
    }

    -- BG + Border
    APBFrames.bg = _G.CreateFrame("Frame", "RealUI_AltPowerBarBG", _G.UIParent)
    APBFrames.bg:SetPoint(db.position.anchorfrom, _G.UIParent, db.position.anchorto, db.position.x, db.position.y)
    _G.Aurora.Base.SetBackdrop(APBFrames.bg)

    -- Bar + Text
    APBFrames.bar = _G.CreateFrame("StatusBar", "RealUI_AltPowerBar", APBFrames.bg)
    APBFrames.bar:SetStatusBarTexture(RealUI.media.textures.plain)
    APBFrames.bar:SetMinMaxValues(0, 100)
    APBFrames.bar:SetPoint("TOPLEFT", APBFrames.bg, "TOPLEFT", 1, -1)
    APBFrames.bar:SetPoint("BOTTOMRIGHT", APBFrames.bg, "BOTTOMRIGHT", -1, 1)

    APBFrames.text = APBFrames.bar:CreateFontString(nil, "OVERLAY")
    APBFrames.text:SetPoint("CENTER", APBFrames.bar)
    APBFrames.text:SetFontObject("SystemFont_Shadow_Med1")
    APBFrames.text:SetTextColor(1, 1, 1, 1)

    -- Update Power
    UpdateInterval = 0
    APBFrames.bar:SetScript("OnUpdate", function(bar, elapsed)
        UpdateInterval = UpdateInterval + elapsed

        if UpdateInterval > 0.1 then
            bar:SetMinMaxValues(0, _G.UnitPowerMax("player", _G.ALTERNATE_POWER_INDEX))
            local CurPower = _G.UnitPower("player", _G.ALTERNATE_POWER_INDEX)
            local MaxPower = _G.UnitPowerMax("player", _G.ALTERNATE_POWER_INDEX)
            bar:SetValue(CurPower)
            if MaxPower > 0 then
                APBFrames.text:SetText(CurPower.."/"..MaxPower)
            else
                APBFrames.text:SetText("0")
            end
            UpdateInterval = 0
        end
    end)

    APBFrames.bg:Hide()
end

-- Initialize
function AltPowerBar:OnInitialize()
    self.db = RealUI.db:RegisterNamespace(MODNAME)
    self.db:RegisterDefaults({
        profile = {
            size = {width = 160, height = 16},
            position = {
                anchorto = "TOP",
                anchorfrom = "TOP",
                x = 0,
                y = -200,
            },
        },
    })
    db = self.db.profile

    self:SetEnabledState(RealUI:GetModuleEnabled(MODNAME))

    AltPowerBar:CreateFrames()
end

function AltPowerBar:OnEnable()
    self:RegisterEvent("PLAYER_LOGIN")
    if RealUI.isPatch then
        self:RegisterEvent("UNIT_POWER_UPDATE", "PowerUpdate")
    else
        self:RegisterEvent("UNIT_POWER", "PowerUpdate")
    end
    self:RegisterEvent("UNIT_POWER_BAR_SHOW", "PowerUpdate")
    self:RegisterEvent("UNIT_POWER_BAR_HIDE", "PowerUpdate")

    -- Hide Default
    _G.PlayerPowerBarAlt:SetAlpha(0)

    if LoggedIn then
        AltPowerBar:RefreshMod()
        AltPowerBar:PowerUpdate()
    end
end

function AltPowerBar:OnDisable()
    self:UnregisterEvent("PLAYER_LOGIN")
    if RealUI.isPatch then
        self:UnregisterEvent("UNIT_POWER_UPDATE")
    else
        self:UnregisterEvent("UNIT_POWER")
    end
    self:UnregisterEvent("UNIT_POWER_BAR_SHOW")
    self:UnregisterEvent("UNIT_POWER_BAR_HIDE")

    APBFrames.bg:Hide()
    _G.PlayerPowerBarAlt:SetAlpha(1)
end
