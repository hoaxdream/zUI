local _, zUI = ...
local m = zUI:CreateModule("Unitframes")

local eventHandler = CreateFrame("Frame", nil, UIParent)
eventHandler:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

function m:OnLoad()
	eventHandler:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

	hooksecurefunc("UnitFrameHealthBar_Update", self.ColorStatusbar)
	hooksecurefunc("HealthBar_OnValueChanged", function(self)
		m.ColorStatusbar(self, self.unit)
	end)

	self:HideFeedbackText(self.db.hideFeedbackText)
	self:EnableCombatIndicator(self.db.combatIndicator)
	self:HidePvPIcons(self.db.hidePvpIcons)
	self:RarePortrait(self.db.rarePortrait)
end

function m:OnProfileChange()
	self:HideFeedbackText(self.db.hideFeedbackText)
	self:EnableCombatIndicator(self.db.combatIndicator)
	self:HidePvPIcons(self.db.hidePvpIcons)
	self:RarePortrait(self.db.rarePortrait)

	UnitFrameHealthBar_Update(PlayerFrameHealthBar, "player")
	UnitFrameHealthBar_Update(TargetFrameHealthBar, "target")
	UnitFrameHealthBar_Update(FocusFrameHealthBar, "focus")
end

-- Class colors on health bars
local sb = _G.GameTooltipStatusBar
function eventHandler:UPDATE_MOUSEOVER_UNIT()
	if m.db.classColors[3] then
		m.ColorStatusbar(sb, "mouseover")
	end
end

local UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS, PlayerFrameHealthBar = UnitIsPlayer
, UnitIsConnected
, UnitClass
, RAID_CLASS_COLORS
, PlayerFrameHealthBar
local _, class, c

function m.ColorStatusbar(statusbar, unit)
	if statusbar == PlayerFrameHealthBar and not m.db.classColors[1] then
		return
	end
	if statusbar ~= PlayerFrameHealthBar and statusbar ~= sb and not m.db.classColors[2] then
		return
	end

	if UnitIsPlayer(unit) and UnitIsConnected(unit) and UnitClass(unit) then
		if unit == statusbar.unit or statusbar == sb then
			_, class = UnitClass(unit)
			c = RAID_CLASS_COLORS[class]
			statusbar:SetStatusBarColor(c.r, c.g, c.b)
		end
	end
end

-- Unitframe class color names
hooksecurefunc("UnitFrame_Update", function(self)
	if UnitClass(self.unit) then
		local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2, UnitClass(self.unit))]
		self.name:SetTextColor(c.r, c.g, c.b, 1)
	end
end)

-- Transparent background
hooksecurefunc("TargetFrame_CheckFaction", function(self)
	self.nameBackground:SetVertexColor(0.0, 0.0, 0.0, 0.5)
end)

-- Ensure chain doesnt clip through pet portrait and rune frame
PetPortrait:GetParent():SetFrameLevel(4)
RuneFrame:SetFrameLevel(4)

-- Chain portrait
function m:RarePortrait(disabled)
	self.db.rarePortrait = disabled
	if disabled then
		PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite.blp")
	else
		PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame.blp")
	end
end

-- Toggle for feedback text
local feedbackText = PlayerFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")

function m:HideFeedbackText(hide)
	self.db.hideFeedbackText = hide
	if hide then
		PlayerFrame.feedbackText = feedbackText
		PlayerFrame.feedbackStartTime = 0
		PetFrame.feedbackText = feedbackText
		PetFrame.feedbackStartTime = 0

		PlayerHitIndicator:Hide()
		PetHitIndicator:Hide()
	else
		local time = GetTime()
		PlayerFrame.feedbackText = PlayerHitIndicator
		PlayerFrame.feedbackStartTime = time
		PetFrame.feedbackText = PetHitIndicator
		PetFrame.feedbackStartTime = time
	end
end

-- Combat indicators for target & focus
m.TargetCombatIndicator = CreateFrame("Frame", nil, TargetFrame)
m.TargetCombatIndicator:SetPoint("LEFT", TargetFrame, "RIGHT", -20, 0)
m.TargetCombatIndicator:SetSize(26, 26)
m.TargetCombatIndicator.icon = m.TargetCombatIndicator:CreateTexture(nil, "BORDER")
m.TargetCombatIndicator.icon:SetAllPoints()
m.TargetCombatIndicator.icon:SetTexture([[Interface\Icons\ABILITY_DUALWIELD]])
m.TargetCombatIndicator:Hide()

m.FocusCombatIndicator = CreateFrame("Frame", nil, FocusFrame)
m.FocusCombatIndicator:SetPoint("LEFT", FocusFrame, "RIGHT", -20, 0)
m.FocusCombatIndicator:SetSize(26, 26)
m.FocusCombatIndicator.icon = m.FocusCombatIndicator:CreateTexture(nil, "BORDER")
m.FocusCombatIndicator.icon:SetAllPoints()
m.FocusCombatIndicator.icon:SetTexture([[Interface\Icons\ABILITY_DUALWIELD]])
m.FocusCombatIndicator:Hide()

m.combatIndicatorElapsed = 0
local combatIndicatorUpdateInterval = 0.1
local UnitAffectingCombat = UnitAffectingCombat

function m.CombatIndicatorUpdate(_, elapsed)
	m.combatIndicatorElapsed = m.combatIndicatorElapsed + elapsed

	if m.combatIndicatorElapsed > combatIndicatorUpdateInterval then
		m.combatIndicatorElapsed = 0
		m.TargetCombatIndicator:SetShown(UnitAffectingCombat("target"))
		m.FocusCombatIndicator:SetShown(UnitAffectingCombat("focus"))
	end
end

function m:EnableCombatIndicator(enable)
	self.db.combatIndicator = enable
	if enable then
		eventHandler:SetScript("OnUpdate", self.CombatIndicatorUpdate)
	else
		eventHandler:SetScript("OnUpdate", nil)
		self.TargetCombatIndicator:Hide()
		self.FocusCombatIndicator:Hide()
	end
end

function m:HidePvPIcons(hide)
	self.db.hidePvpIcons = hide

	hide = hide and 0 or 1
	PlayerPVPIcon:SetAlpha(hide)
	PlayerPrestigeBadge:SetAlpha(hide)
	PlayerPrestigePortrait:SetAlpha(hide)
	TargetFrameTextureFramePVPIcon:SetAlpha(hide)
	TargetFrameTextureFramePrestigeBadge:SetAlpha(hide)
	TargetFrameTextureFramePrestigePortrait:SetAlpha(hide)
	FocusFrameTextureFramePVPIcon:SetAlpha(hide)
	FocusFrameTextureFramePrestigeBadge:SetAlpha(hide)
	FocusFrameTextureFramePrestigePortrait:SetAlpha(hide)
end

m.defaultSettings = {
	hideFeedbackText = true,
	combatIndicator = true,
	hidePvpIcons = true,
	rarePortrait = true,
	classColors = {
		true, -- Player
		true, -- Others
		false, -- Tooltip
	},
}

m.optionsTable = {
	hideFeedbackText = {
		name = "Feedback Text",
		desc = "Disable healing/damage text in player and pet portrait.",
		type = "toggle",
		width = "full",
		order = 1,
		set = function(info, val)
			m:HideFeedbackText(val)
		end,
	},
	hidePvpIcons = {
		name = "PvP Icons",
		desc = "Disable pvp icon/prestige badge in player portrait.",
		type = "toggle",
		width = "full",
		order = 2,
		set = function(info, val)
			m:HidePvPIcons(val)
		end,
	},
	combatIndicator = {
		name = "Combat Indicator",
		desc = "Combat icon indicator for target and focus.",
		type = "toggle",
		width = "full",
		order = 3,
		set = function(info, val)
			m:EnableCombatIndicator(val)
		end,
	},
	rarePortrait = {
		name = "Rare Portrait",
    desc = "Elite silver dragon rare portrait in player portrait.",
		type = "toggle",
		width = "full",
		order = 4,
		set = function(info, val)
			m:RarePortrait(val)
		end,
	},
	classColors = {
		name = "Class Colors",
		type = "multiselect",
		order = 5,
		get = function(info, val)
			return m.db.classColors[val]
		end,
		set = function(info, key, val)
			m.db.classColors[key] = val
			UnitFrameHealthBar_Update(PlayerFrameHealthBar, "player")
			UnitFrameHealthBar_Update(TargetFrameHealthBar, "target")
			UnitFrameHealthBar_Update(FocusFrameHealthBar, "focus")
		end,
		values = {
			"Player",
			"Others",
			"Tooltip",
		},
	},
}
