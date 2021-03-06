local ADDON_NAME, private = ...

-- Lua Globals --
-- luacheck: globals floor next type tonumber max

local Aurora = private.Aurora
local RealUI = _G.RealUI

local debug = RealUI.GetDebug("Skins")
private.debug = debug

local LSM = _G.LibStub("LibSharedMedia-3.0")
local defaults = {
    profile = {
        stripeAlpha = 0.5,
        buttonColor = {
        },
        frameColor = {
            a = 0.7
        },
        classColors = {
        },
        uiModScale = 1,
        customScale = 1,
        isHighRes = false,
        isPixelScale = true,
        fonts = {
            normal = LSM:Fetch("font", "Roboto"),
            chat = LSM:Fetch("font", "Roboto Condensed"),
            crit = LSM:Fetch("font", "Roboto Bold-Italic"),
            header = LSM:Fetch("font", "Roboto Slab"),
        },
        addons = {
            ["**"] = true
        }
    }
}

RealUI.media = {
    colors = {
        red =       {0.85, 0.14, 0.14, 1},
        orange =    {1.00, 0.38, 0.08, 1},
        amber =     {1.00, 0.64, 0.00, 1},
        yellow =    {1.00, 1.00, 0.15, 1},
        green =     {0.13, 0.90, 0.13, 1},
        cyan =      {0.11, 0.92, 0.72, 1},
        blue =      {0.15, 0.61, 1.00, 1},
        purple =    {0.70, 0.28, 1.00, 1},
    },
    textures = {
        plain = [[Interface\Buttons\WHITE8x8]],
    },
}

local uiScaleChanging
local uiMod, pixelScale
function RealUI.UpdateUIScale(newScale)
    if uiScaleChanging then return end

    local _, pysHeight = _G.GetPhysicalScreenSize()
    uiMod = (pysHeight / 768) * (private.uiScale or 1)
    pixelScale = 768 / pysHeight

    -- Get Scale
    local oldScale = private.skinsDB.customScale
    if private.skinsDB.isPixelScale then
        newScale = pixelScale
    end

    local cvarScale, parentScale = tonumber(_G.GetCVar("uiscale")), RealUI.Round(_G.UIParent:GetScale(), 2)
    private.debug("scale", pixelScale, cvarScale, parentScale)

    if not newScale then
        newScale = _G.min(cvarScale, parentScale)
    end
    private.debug("newScale", newScale)

    local uiScale = newScale
    if private.skinsDB.isHighRes then
        uiScale = uiScale * 2
    end
    private.debug("uiScale", oldScale, uiScale)

    if oldScale ~= newScale or max(cvarScale, parentScale) ~= uiScale then
        uiScaleChanging = true
        -- Set Scale (WoW CVar can't go below .64)

        if cvarScale ~= uiScale then
            --[[ Setting the `uiScale` cvar will taint the ObjectiveTracker, and by extention the
                WorldMap and map action button. As such, we only use that if we absolutly have to.]]
            _G.SetCVar("uiScale", max(uiScale, 0.64))
        end
        if parentScale ~= uiScale then
            _G.UIParent:SetScale(uiScale)
        end
        private.skinsDB.customScale = newScale
        uiScaleChanging = false
    end
end

local ScaleAPI = {}
local previewFrames = {}
function RealUI.RegisterModdedFrame(frame, updateFunc)
    -- Frames that are sized via ModValue become HUGE with retina scale.
    if private.skinsDB.isHighRes then
        frame:SetScale(private.skinsDB.customScale)
    elseif private.skinsDB.customScale > pixelScale then
        frame:SetScale(pixelScale)
    end

    if updateFunc then
        previewFrames[frame] = updateFunc
    end
end
function RealUI.PreviewModScale()
    private.uiScale = private.skinsDB.uiModScale
    private.UpdateUIScale()
    for frame, func in next, previewFrames do
        func(frame)
    end
end

local skinnedFrames = {}
function RealUI:RegisterSkinnedFrame(frame, color, stripes)
    skinnedFrames[frame] = {
        color = color,
        stripes = stripes
    }
end
function RealUI:UpdateFrameStyle()
    for frame, style in next, skinnedFrames do
        if style.stripes then
            Aurora.Base.SetBackdropColor(frame, style.color, private.skinsDB.frameColor.a)
            style.stripes:SetAlpha(private.skinsDB.stripeAlpha)
        else
            Aurora.Base.SetBackdropColor(frame, style.color)
        end
    end
end

function private.OnLoad()
    --print("OnLoad Aurora", Aurora, private.Aurora)
    local skinsDB = _G.LibStub("AceDB-3.0"):New("RealUI_SkinsDB", defaults, true)
    skinsDB:RegisterCallback("OnProfileChanged", function(db, newProfile)
        RealUI:ReloadUIDialog()
    end)
    skinsDB:RegisterCallback("OnProfileCopied", function(db, sourceProfile)
        RealUI:ReloadUIDialog()
    end)
    skinsDB:RegisterCallback("OnProfileReset", function(db)
        RealUI:ReloadUIDialog()
    end)

    private.skinsDB = skinsDB.profile
    RealUI:RegisterAddOnDB(ADDON_NAME, skinsDB)

    -- Transfer settings
    if _G.RealUI_Storage.nibRealUI_Init then
        local RealUI_InitDB = _G.RealUI_Storage.nibRealUI_Init.RealUI_InitDB
        if RealUI_InitDB then
            private.skinsDB.stripeAlpha = RealUI_InitDB.stripeOpacity
            private.skinsDB.uiModScale = RealUI_InitDB.uiModScale
        end
        _G.RealUI_Storage.nibRealUI_Init = nil
    end

    if _G.RealUI_Storage.Aurora then
        local AuroraConfig = _G.RealUI_Storage.Aurora.AuroraConfig
        private.skinsDB.frameColor.a = AuroraConfig.alpha
        if type(AuroraConfig.customClassColors) == "table" then
            private.skinsDB.customClassColors = AuroraConfig.customClassColors
        end
        _G.RealUI_Storage.Aurora = nil
    end

    if _G.RealUI_Storage.nibRealUI and _G.RealUI_Storage.nibRealUI.nibRealUIDB then
        local profile = _G.RealUI_Storage.nibRealUI.nibRealUIDB.profiles.RealUI
        if profile and profile.media and profile.media.font then
            local font = profile.media.font
            if font.standard then
                private.skinsDB.fonts.normal = font.standard[4]
            end
            if font.chat then
                private.skinsDB.fonts.chat = font.chat[4]
            end
            if font.crit then
                private.skinsDB.fonts.crit = font.crit[4]
            end
            if font.header then
                private.skinsDB.fonts.header = font.header[4]
            end
            profile.media.font = nil
        end

        local global = _G.RealUI_Storage.nibRealUI.nibRealUIDB.global
        if global and global.retinaDisplay then
            private.skinsDB.isHighRes = global.retinaDisplay.set
            global.retinaDisplay = nil
        end

        local namespace = _G.RealUI_Storage.nibRealUI.nibRealUIDB.namespaces.UIScaler
        if namespace and namespace.profiles.RealUI then
            local customScale = _G.tonumber(namespace.profiles.RealUI.customScale)
            if customScale then
                private.skinsDB.customScale = customScale
            end
            private.skinsDB.isPixelScale = namespace.profiles.RealUI.pixelScale
            _G.RealUI_Storage.nibRealUI.nibRealUIDB.namespaces.UIScaler = nil
        end
    else
        _G.ReloadUI()
    end

    -- Set flags
    private.disabled.bags = true
    private.disabled.mainmenubar = true
    private.disabled.pixelScale = not private.skinsDB.isPixelScale

    private.uiScale = private.skinsDB.uiModScale
    private.UpdateUIScale = RealUI.UpdateUIScale
    for fontType, fontPath in next, private.skinsDB.fonts do
        private.font[fontType] = fontPath
    end

    local Base, Scale = Aurora.Base, Aurora.Scale
    local Hook, Skin = Aurora.Hook, Aurora.Skin
    local Color = Aurora.Color

    if private.disabled.uiScale then
        RealUI.Scale = ScaleAPI
    else
        Aurora.Scale.Value = ScaleAPI.Value
        RealUI.Scale = Scale
    end

    -- Initialize custom colors
    local frameColor = private.skinsDB.frameColor
    if not frameColor.r then
        frameColor.r, frameColor.g, frameColor.b = Color.frame:GetRGB()
    else
        Color.frame:SetRGBA(frameColor.r, frameColor.g, frameColor.b, Color.frame.a)
    end

    local buttonColor = private.skinsDB.buttonColor
    if not buttonColor.r then
        buttonColor.r, buttonColor.g, buttonColor.b = Color.button:GetRGB()
    else
        Color.button:SetRGB(buttonColor.r, buttonColor.g, buttonColor.b)
    end

    local classColors = private.skinsDB.classColors
    if not classColors[private.charClass.token] then
        private.classColorsReset(classColors, true)
    end

    function private.classColorsHaveChanged()
        local hasChanged = false
        for i = 1, #_G.CLASS_SORT_ORDER do
            local classToken = _G.CLASS_SORT_ORDER[i]
            local color = _G.CUSTOM_CLASS_COLORS[classToken]
            local cache = classColors[classToken]

            if not color:IsEqualTo(cache) then
                --print("Change found in", classToken)
                color:SetRGB(cache.r, cache.g, cache.b)
                hasChanged = true
            end
        end
        return hasChanged
    end
    function private.classColorsInit()
        if private.classColorsHaveChanged() then
            private.updateHighlightColor()
        end
    end
    _G.CUSTOM_CLASS_COLORS:RegisterCallback(function()
        private.updateHighlightColor()
    end)

    -- Set overrides and hooks
    if private.isPatch then
        function Hook.GameTooltip_SetBackdropStyle(self, style)
            Base.SetBackdrop(self, Color.frame, frameColor.a)
        end
    else
        function Hook.GameTooltip_OnHide(gametooltip)
            Base.SetBackdropColor(gametooltip, Color.frame, frameColor.a)
        end
    end

    _G.hooksecurefunc(Skin, "AzeriteEmpoweredItemUITemplate", function(Frame)
        skinnedFrames[Frame.BorderFrame].stripes:SetParent(Frame)
    end)
    _G.hooksecurefunc(Base, "SetBackdrop", function(Frame, color, alpha)
        if not color and not alpha then
            local r, g, b, a = Frame:GetBackdropColor()
            Frame:SetBackdropColor(r, g, b, frameColor.a)

            local stripes = Frame:CreateTexture(nil, "BACKGROUND", nil, -6)
            stripes:SetTexture([[Interface\AddOns\nibRealUI\Media\StripesThin]], true, true)
            stripes:SetAlpha(private.skinsDB.stripeAlpha)
            stripes:SetAllPoints()
            stripes:SetHorizTile(true)
            stripes:SetVertTile(true)
            stripes:SetBlendMode("ADD")

            r, g, b = Frame:GetBackdropBorderColor()
            if Color.frame:IsEqualTo(r, g, b, a) then
                color = Color.frame
            else
                color = Color.button
            end
            RealUI:RegisterSkinnedFrame(Frame, color, stripes)
        end
    end)

    -- Disable user selected addon skins
    for name, enabled in next, private.skinsDB.addons do
        if not name:find("RealUI") and not enabled then
            private.AddOns[name] = private.nop
        end
    end

    function private.AddOns.nibRealUI()
        if _G.nibRealUIDB.profiles.RealUI then
            local profile = _G.nibRealUIDB.profiles.RealUI
            if profile.media.font then
                profile.media.font = nil
            end

            if _G.nibRealUIDB.global.retinaDisplay then
                _G.nibRealUIDB.global.retinaDisplay = nil
            end

            if _G.nibRealUIDB.namespaces.UIScaler then
                _G.nibRealUIDB.namespaces.UIScaler = nil
            end
        end
        if not _G.IsAddOnLoaded("Ace3") then
            private.AddOns.Ace3()
        end

        --f.f = "f" -- error for testing RealUI_Bugs
    end

    function private.AddOns.RealUI_Bugs()
        local errorFrame = _G.RealUI_ErrorFrame
        Skin.UIPanelDialogTemplate(errorFrame)
        Skin.UIPanelScrollFrameTemplate(errorFrame.ScrollFrame)
        Skin.UIPanelButtonTemplate(errorFrame.Reload)
        Skin.NavButtonPrevious(errorFrame.PreviousError)
        Skin.NavButtonNext(errorFrame.NextError)

        --[[ Scale ]]--
        errorFrame.ScrollFrame:SetPoint(errorFrame.ScrollFrame:GetPoint(1))
        errorFrame.ScrollFrame:SetPoint(errorFrame.ScrollFrame:GetPoint(2))
        Scale.RawSetSize(errorFrame.ScrollFrame.Text, errorFrame.ScrollFrame:GetSize())
        errorFrame.Reload:SetPoint(errorFrame.Reload:GetPoint())
        errorFrame.PreviousError:SetPoint(errorFrame.PreviousError:GetPoint())
        errorFrame.NextError:SetPoint(errorFrame.NextError:GetPoint())
    end
end

--[[ Copy Scale API from Aurora until the entire UI is upgraded. ]]--
function ScaleAPI.Value(value, getFloat)
    local mult = getFloat and 100 or 1
    return floor((value * uiMod) * mult + 0.5) / mult
end

function ScaleAPI.Size(self, width, height)
    if not (width and height) then
        width, height = self:GetSize()
    end
    return self:SetSize(ScaleAPI.Value(width), ScaleAPI.Value(height))
end

function ScaleAPI.Height(self, height)
    if not (height) then
        height = self:GetHeight()
    end
    return self:SetHeight(ScaleAPI.Value(height))
end

function ScaleAPI.Width(self, width)
    if not (width) then
        width = self:GetWidth()
    end
    return self:SetWidth(ScaleAPI.Value(width))
end

function ScaleAPI.Thickness(self, thickness)
    if not (thickness) then
        thickness = self:GetThickness()
    end
    return self:SetThickness(ScaleAPI.Value(thickness))
end

local ScaleArgs do
    local function pack(t, ...)
        for i = 1, _G.select("#", ...) do
            t[i] = _G.select(i, ...)
        end
    end

    local args = {}
    function ScaleArgs(self, method, ...)
        if self.debug then
            private.debug("raw args", method, ...)
        end
        _G.wipe(args)
        --[[ This function gets called A LOT, so we recycle this table
            to reduce needless garbage creation.]]
        if ... then
            pack(args, ...)
        else
            pack(args, self["Get"..method](self))
        end

        for i = 1, #args do
            if _G.type(args[i]) == "number" then
                args[i] = ScaleAPI.Value(args[i])
            end
        end
        if self.debug then
            private.debug("final args", method, _G.unpack(args))
        end
        return args
    end
end

function ScaleAPI.Point(self, ...)
    self:SetPoint(_G.unpack(ScaleArgs(self, "Point", ...)))
end

function ScaleAPI.EndPoint(self, ...)
    self:SetEndPoint(_G.unpack(ScaleArgs(self, "EndPoint", ...)))
end
function ScaleAPI.StartPoint(self, ...)
    self:SetStartPoint(_G.unpack(ScaleArgs(self, "StartPoint", ...)))
end
