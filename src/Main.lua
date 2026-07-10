local addonName, PIS = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons

-- Initialize addon namespace
PIS.name = addonName
PIS.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

local MIN_QUERY_LENGTH = 2
local MAX_RESULTS = 1000
local SEARCH_DELAY = 0.15

-- Hand the icon grid back to Blizzard's own data provider
local function RestoreDefaultIcons(popup)
	popup.IconSelector:SetSelectionsDataProvider(
		GenerateClosure(popup.GetIconByIndex, popup),
		GenerateClosure(popup.GetNumIcons, popup)
	)
	popup.IconSelector:UpdateSelections()
	popup:ReevaluateSelectedIcon()
end

-- Swap the icon grid to only show icons of items matching the query
local function ShowSearchResults(popup, query)
	local results = PIS.Search:Find(query, MAX_RESULTS)
	local icons = {}
	for i, result in ipairs(results) do
		icons[i] = result.icon
	end

	popup.IconSelector:SetSelectionsDataProvider(
		function(index) return icons[index] end,
		function() return #icons end
	)

	-- Keep the current selection highlighted if it appears in the results
	local selectedIcon = popup.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
	local selectedIndex
	for i, icon in ipairs(icons) do
		if icon == selectedIcon then
			selectedIndex = i
			break
		end
	end
	popup.IconSelector:SetSelectedIndex(selectedIndex)
	popup.IconSelector:UpdateSelections()
	popup.IconSelector:ScrollToSelectedIndex()
	popup:SetSelectedIconText()
end

local function OnQueryChanged(popup, query)
	if not popup:IsShown() then
		return
	end

	query = query:match("^%s*(.-)%s*$")
	if #query >= MIN_QUERY_LENGTH then
		ShowSearchResults(popup, query)
	else
		RestoreDefaultIcons(popup)
	end
end

local function AttachSearchBox(popup)
	if popup.PeaversIconSearchBox then
		return
	end

	local box = CreateFrame("EditBox", "PeaversIconSearchBox", popup.BorderBox, "SearchBoxTemplate")
	box:SetSize(180, 22)
	box:SetPoint("RIGHT", popup.BorderBox.IconTypeDropdown, "LEFT", -12, 0)
	box:SetAutoFocus(false)
	box.Instructions:SetText("Search items...")
	popup.PeaversIconSearchBox = box

	local pendingTimer
	box:HookScript("OnTextChanged", function(self)
		if pendingTimer then
			pendingTimer:Cancel()
		end
		pendingTimer = C_Timer.NewTimer(SEARCH_DELAY, function()
			pendingTimer = nil
			OnQueryChanged(popup, self:GetText())
		end)
	end)

	-- Blizzard resets the grid in its own OnShow; start each session unfiltered
	popup:HookScript("OnShow", function()
		box:SetText("")
	end)

	-- Blizzard swaps the grid for a drop target while an item is on the cursor;
	-- follow the dropdown's visibility so the box doesn't float over it
	hooksecurefunc(popup, "UpdateStateFromCursorType", function(self)
		box:SetShown(self.BorderBox.IconTypeDropdown:IsShown())
	end)
end

local function TryHook()
	local popup = _G.TransmogFrame and _G.TransmogFrame.OutfitPopup
	if popup then
		AttachSearchBox(popup)
	end
end

-- Initialize the addon
PeaversCommons.Events:Init(addonName, function()
	-- Blizzard_Transmog is load-on-demand; hook once it exists. Don't use
	-- PeaversCommons.Events for this: Events:Init wipes every ADDON_LOADED
	-- handler once this addon initializes.
	EventUtil.ContinueOnAddOnLoaded("Blizzard_Transmog", TryHook)
end, {
	suppressAnnouncement = true
})
