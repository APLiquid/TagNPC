-- TagNPC.lua (final working version with scrollbox UI)

local f = CreateFrame("Frame")
local ICON_PATH = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"

local iconID
local mobNamesToTrack = {}
local nameplateIcons = {}
local dropdownCounter = 0

-- Saved variables setup in ADDON_LOADED
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "TagNPC" then
        TagNPCDB = TagNPCDB or {}
        TagNPCDB.iconID = TagNPCDB.iconID or 8
        TagNPCDB.trackedNPCs = TagNPCDB.trackedNPCs or {}
        iconID = TagNPCDB.iconID
        mobNamesToTrack = TagNPCDB.trackedNPCs or {}

        local iconTexture = "|T" .. ICON_PATH .. iconID .. ":16|t"
        print("|cff33ff99[TagNPC]|r: Loaded icon:", iconTexture)

        RefreshNPCList()

        -- Start scanner
        self:SetScript("OnUpdate", function(self, elapsed)
            self.timer = (self.timer or 0) + elapsed
            if self.timer > 0.2 then
                self.timer = 0
                ScanNameplates()
            end
        end)
    end
end)

-- Nameplate handling
local function AddIcon(plate, iconID)
    if nameplateIcons[plate] then return end
    local icon = plate:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(ICON_PATH .. iconID)
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", plate, "LEFT", -17, 1)
    nameplateIcons[plate] = icon
end

function ScanNameplates()
    for i = 1, WorldFrame:GetNumChildren() do
        local plate = select(i, WorldFrame:GetChildren())
        if plate:IsShown() and not plate:GetName() then
            local regions = {plate:GetRegions()}
            for _, region in ipairs(regions) do
                if region and region:GetObjectType() == "FontString" and region:GetText() then
                    local mobName = region:GetText()
					local npcIconID = mobNamesToTrack[mobName]
					if npcIconID then
						AddIcon(plate, npcIconID)
					end
                end
            end
        end
    end
end

-- UI Panel
local panel = CreateFrame("Frame")
panel.name = "TagNPC"
InterfaceOptions_AddCategory(panel)

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("TagNPC Settings")

-- Icon dropdown
local iconOptions = {
    [1] = "Star", [2] = "Circle", [3] = "Diamond", [4] = "Triangle",
    [5] = "Moon", [6] = "Square", [7] = "Cross", [8] = "Skull"
}

local defaultIconLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
defaultIconLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
defaultIconLabel:SetText("Default Icon:")


local dropdown = CreateFrame("Frame", "TagNPCDropdown", panel, "UIDropDownMenuTemplate")
--dropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -15, -10)
dropdown:SetPoint("LEFT", defaultIconLabel, "RIGHT", 5, 0)
UIDropDownMenu_SetWidth(dropdown, 120)
UIDropDownMenu_Initialize(dropdown, function(self)
    for id, name in pairs(iconOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = "|T" .. ICON_PATH .. id .. ":16|t " .. name
        info.arg1 = id
        info.func = function(_, arg1)
            TagNPCDB.iconID = arg1
            iconID = arg1
            UIDropDownMenu_SetText(dropdown, "|T" .. ICON_PATH .. arg1 .. ":16|t " .. iconOptions[arg1])
            for plate, icon in pairs(nameplateIcons) do if icon and icon:IsShown() then icon:Hide() end end
            wipe(nameplateIcons)
            ScanNameplates()
        end
        UIDropDownMenu_AddButton(info)
    end
end)

local function InitDropdownSelection()
    UIDropDownMenu_SetText(dropdown, "|T" .. ICON_PATH .. iconID .. ":16|t " .. (iconOptions[iconID] or "Unknown"))
end
panel:SetScript("OnShow", InitDropdownSelection)

-- Tracked NPC UI
local npcLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
npcLabel:SetPoint("TOPLEFT", defaultIconLabel, "BOTTOMLEFT", 0, -15)
npcLabel:SetText("Tracked NPCs:")

local scrollFrame = CreateFrame("ScrollFrame", "TagNPCScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", npcLabel, "BOTTOMLEFT", 0, -5)
scrollFrame:SetSize(360, 150)


local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(340, 800)
scrollFrame:SetScrollChild(scrollChild)

local npcButtons = {}
function RefreshNPCList()
    for _, row in ipairs(npcButtons) do row:Hide() end
    wipe(npcButtons)
	local sortedNames = {}
	for name in pairs(TagNPCDB.trackedNPCs) do
		table.insert(sortedNames, name)
	end
	table.sort(sortedNames)	
    local i = 0
    for _, name in pairs(sortedNames) do
        i = i + 1
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(340, 22)
        row:SetPoint("TOPLEFT", 0, -((i - 1) * 22))

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", 5, 0)
        nameText:SetText(name)
		nameText:SetWidth(190)
		nameText:SetJustifyH("LEFT")
		
		-- Create dropdown
		dropdownCounter = dropdownCounter + 1 
		local npcDropdown = CreateFrame("Frame", "TagNPCDrop_" .. dropdownCounter, row, "UIDropDownMenuTemplate")

		
		npcDropdown:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
		UIDropDownMenu_SetWidth(npcDropdown, 80)

		UIDropDownMenu_Initialize(npcDropdown, function(self)
			for id, iconName in pairs(iconOptions) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = "|T" .. ICON_PATH .. id .. ":16|t " .. iconName
				info.arg1 = name
				info.arg2 = id
				info.func = function(_, npcName, selectedID)
					TagNPCDB.trackedNPCs[npcName] = selectedID
					mobNamesToTrack[npcName] = selectedID
					print("|cff33ff99[TagNPC]|r: Updated icon for " .. npcName)
					UIDropDownMenu_SetText(npcDropdown, "|T" .. ICON_PATH .. selectedID .. ":16|t " .. iconOptions[selectedID])
					for plate, icon in pairs(nameplateIcons) do if icon and icon:IsShown() then icon:Hide() end end
					wipe(nameplateIcons)
					ScanNameplates()
				end
				UIDropDownMenu_AddButton(info)
			end
		end)

		UIDropDownMenu_SetText(npcDropdown, "|T" .. ICON_PATH .. (TagNPCDB.trackedNPCs[name] or 8) .. ":16|t " .. iconOptions[TagNPCDB.trackedNPCs[name] or 8])


        local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        removeBtn:SetText("Del.")
		removeBtn:SetSize(40, 18)
		removeBtn:SetPoint("LEFT", npcDropdown, "RIGHT", -10, 0)
        removeBtn:SetScript("OnClick", function()
            TagNPCDB.trackedNPCs[name] = nil
            mobNamesToTrack[name] = nil
            print("|cff33ff99[TagNPC]|r: Removed NPC:", name)
            for plate, icon in pairs(nameplateIcons) do if icon and icon:IsShown() then icon:Hide() end end
            wipe(nameplateIcons)
            ScanNameplates()
            RefreshNPCList()
        end)

        table.insert(npcButtons, row)
    end
end

-- Input box + add button
local npcInput = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
npcInput:SetSize(200, 20)
npcInput:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
npcInput:SetAutoFocus(false)

local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
addButton:SetSize(60, 20)
addButton:SetPoint("LEFT", npcInput, "RIGHT", 5, 0)
addButton:SetText("Add")
addButton:SetScript("OnClick", function()
    local name = npcInput:GetText()
    if name and name ~= "" and not TagNPCDB.trackedNPCs[name] then
        TagNPCDB.trackedNPCs[name] = iconID
		mobNamesToTrack[name] = iconID
        npcInput:SetText("")
        print("|cff33ff99[TagNPC]|r: Added NPC:", name)
        for plate, icon in pairs(nameplateIcons) do if icon and icon:IsShown() then icon:Hide() end end
        wipe(nameplateIcons)
        ScanNameplates()
        RefreshNPCList()
    end
end)

SLASH_TAGNPC1 = "/tagnpc"
SlashCmdList["TAGNPC"] = function(msg)
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "" then
        -- Open the settings panel
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel) -- Called twice due to Blizzard bug
    elseif cmd == "add" and rest ~= "" then
        if not TagNPCDB.trackedNPCs[rest] then
            TagNPCDB.trackedNPCs[rest] = TagNPCDB.iconID or 8
            mobNamesToTrack[rest] = TagNPCDB.iconID or 8
            print("|cff33ff99[TagNPC]|r: Added NPC:", rest)
            wipe(nameplateIcons)
            ScanNameplates()
            RefreshNPCList()
        else
            print("|cff33ff99[TagNPC]|r: NPC already tracked:", rest)
        end
    elseif cmd == "del" and rest ~= "" then
		if TagNPCDB.trackedNPCs[rest] then
			TagNPCDB.trackedNPCs[rest] = nil
			mobNamesToTrack[rest] = nil
			print("|cff33ff99[TagNPC]|r: Removed NPC:", rest)

			-- Hide and remove existing icons that match this NPC
			for plate, icon in pairs(nameplateIcons) do
				if plate:IsShown() then
					local regions = {plate:GetRegions()}
					for _, region in ipairs(regions) do
						if region and region:GetObjectType() == "FontString" and region:GetText() == rest then
							icon:Hide()
							nameplateIcons[plate] = nil
							break
						end
					end
				end
			end

			ScanNameplates()
			RefreshNPCList()
		else
			print("|cff33ff99[TagNPC]|r: NPC not found:", rest)
		end
	else
        print("|cff33ff99[TagNPC]|r Usage:")
        print("  /tagnpc             - Open settings")
        print("  /tagnpc add [name]  - Add NPC to track (e.g. /tagnpc add Angry Villager)")
        print("  /tagnpc del [name] - Remove tracked NPC")
    end
end