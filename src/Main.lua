local addonName, PIS = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons

-- Initialize addon namespace
PIS.name = addonName
PIS.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

local MIN_QUERY_LENGTH = 2
local MAX_RESULTS = 1000
local SEARCH_DELAY = 0.15

-- Dropdown entries: label -> exact tag word in the item database (the tag
-- vocabulary is defined by the iconsearch-module in PeaversAddonDataSupplier)
local TYPE_GROUPS = {
	{
		text = "Armor",
		options = {
			{ "Head", "head" },
			{ "Shoulders", "shoulder" },
			{ "Chest", "chest" },
			{ "Back", "back" },
			{ "Wrist", "wrist" },
			{ "Hands", "hands" },
			{ "Waist", "waist" },
			{ "Legs", "legs" },
			{ "Feet", "feet" },
			{ "Shield", "shield" },
			{ "Off-hand", "offhand" },
			{ "Neck", "neck" },
			{ "Ring", "ring" },
			{ "Trinket", "trinket" },
			{ "Shirt", "shirt" },
			{ "Tabard", "tabard" },
		},
	},
	{
		text = "Weapons",
		options = {
			{ "Any Weapon", "weapon" },
			{ "Axe", "axe" },
			{ "Bow", "bow" },
			{ "Crossbow", "crossbow" },
			{ "Dagger", "dagger" },
			{ "Fist Weapon", "fist" },
			{ "Gun", "gun" },
			{ "Mace", "mace" },
			{ "Polearm", "polearm" },
			{ "Staff", "staff" },
			{ "Sword", "sword" },
			{ "Wand", "wand" },
			{ "Warglaive", "warglaive" },
		},
	},
}

-- Hand the icon grid back to Blizzard's own data provider
local function RestoreDefaultIcons(popup)
	popup.IconSelector:SetSelectionsDataProvider(
		GenerateClosure(popup.GetIconByIndex, popup),
		GenerateClosure(popup.GetNumIcons, popup)
	)
	popup.IconSelector:UpdateSelections()
	popup:ReevaluateSelectedIcon()
end

-- Swap the icon grid to only show icons of items matching query/typeTags
local function ShowSearchResults(popup, query, typeTags)
	local results = PIS.Search:Find(query, typeTags, MAX_RESULTS)
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

local function AttachSearchBox(popup)
	if popup.PeaversIconSearchButton then
		return
	end

	local selectedTypes = {}
	local searchText = ""

	-- A single funnel button next to Blizzard's icon dropdown; it opens a
	-- menu holding the search box and the item type checkboxes. Same filter
	-- funnel the quest tracker uses: dimmed at rest, bright on hover, gold
	-- while a filter is active.
	local button = CreateFrame("DropdownButton", "PeaversIconSearchButton", popup.BorderBox)
	button:SetSize(20, 21)
	button:SetPoint("RIGHT", popup.BorderBox.IconTypeDropdown, "LEFT", -8, 0)
	button:SetNormalAtlas("ui-questtrackerbutton-filter")
	button:SetPushedAtlas("ui-questtrackerbutton-filter-pressed")
	button:SetHighlightAtlas("ui-questtrackerbutton-filter", "ADD")
	button:GetHighlightTexture():SetAlpha(0.25)
	popup.PeaversIconSearchButton = button

	local mouseOver = false

	local function UpdateActiveIndicator()
		local active = searchText ~= "" or next(selectedTypes) ~= nil
		local texture = button:GetNormalTexture()
		if active then
			texture:SetVertexColor(1, 0.82, 0)
		else
			texture:SetVertexColor(1, 1, 1)
		end
		texture:SetAlpha((active or mouseOver) and 1 or 0.71)
	end

	button:SetScript("OnEnter", function(self)
		mouseOver = true
		UpdateActiveIndicator()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Search Icons by Item")
		GameTooltip:AddLine("Search item names or filter by item type.", 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		mouseOver = false
		UpdateActiveIndicator()
		GameTooltip:Hide()
	end)
	UpdateActiveIndicator()

	local function RunFilter()
		UpdateActiveIndicator()
		if not popup:IsShown() then
			return
		end

		local query = searchText
		if #query < MIN_QUERY_LENGTH then
			query = ""
		end

		local typeTags = {}
		for _, group in ipairs(TYPE_GROUPS) do
			for _, option in ipairs(group.options) do
				if selectedTypes[option[2]] then
					typeTags[#typeTags + 1] = option[2]
				end
			end
		end

		if query == "" and #typeTags == 0 then
			RestoreDefaultIcons(popup)
		else
			ShowSearchResults(popup, query, typeTags)
		end
	end

	local function IsTypeSelected(tag)
		return selectedTypes[tag] == true
	end

	local function ToggleType(tag)
		selectedTypes[tag] = not selectedTypes[tag] or nil
		RunFilter()
	end

	local function IsAllSelected()
		return next(selectedTypes) == nil
	end

	local function SelectAll()
		wipe(selectedTypes)
		RunFilter()
	end

	local pendingTimer
	local function OnSearchTextChanged(box)
		SearchBoxTemplate_OnTextChanged(box)

		local text = box:GetText():match("^%s*(.-)%s*$")
		if text == searchText then
			return
		end
		searchText = text

		if pendingTimer then
			pendingTimer:Cancel()
		end
		pendingTimer = C_Timer.NewTimer(SEARCH_DELAY, function()
			pendingTimer = nil
			RunFilter()
		end)
	end

	button:SetupMenu(function(_, rootDescription)
		-- Menu element frames are pooled: (re)apply state and scripts each
		-- time the menu opens, with SetScript rather than HookScript
		local searchBox = rootDescription:CreateTemplate("SearchBoxTemplate")
		searchBox:AddInitializer(function(box)
			box:SetScript("OnTextChanged", OnSearchTextChanged)
			box.Instructions:SetText("Search items...")
			box:SetAutoFocus(false)
			-- Menu-pooled edit boxes lose the template's text insets; without
			-- them the typed text overlaps the magnifier icon
			box:SetTextInsets(16, 20, 0, 0)
			box:SetText(searchText)
			return 200, 22
		end)

		rootDescription:CreateDivider()
		rootDescription:CreateCheckbox("All Items", IsAllSelected, SelectAll)
		for _, group in ipairs(TYPE_GROUPS) do
			local submenu = rootDescription:CreateButton(group.text)
			for _, option in ipairs(group.options) do
				submenu:CreateCheckbox(option[1], IsTypeSelected, ToggleType, option[2])
			end
		end
	end)

	-- Blizzard resets the grid in its own OnShow; start each session unfiltered
	popup:HookScript("OnShow", function()
		searchText = ""
		wipe(selectedTypes)
		UpdateActiveIndicator()
	end)

	popup:HookScript("OnHide", function()
		if button:IsMenuOpen() then
			button:CloseMenu()
		end
	end)

	-- Blizzard swaps the grid for a drop target while an item is on the cursor;
	-- follow the dropdown's visibility so our button doesn't float over it
	hooksecurefunc(popup, "UpdateStateFromCursorType", function(self)
		button:SetShown(self.BorderBox.IconTypeDropdown:IsShown())
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
	-- PeaversCommons.Events for this: Events:Init used to wipe every
	-- ADDON_LOADED handler once this addon initialized.
	EventUtil.ContinueOnAddOnLoaded("Blizzard_Transmog", TryHook)

	-- Register with PeaversConfig registry
	if PeaversCommons.ConfigRegistry then
		PeaversCommons.ConfigRegistry:Register({
			name = "PeaversIconSearch",
			displayName = "Icon Search",
			description = "Item search for the transmog outfit icon picker",
			addonRef = PIS,
			pages = PIS.ConfigUI:GetPages(),
			order = 13,
		})
	end
end, {
	suppressAnnouncement = true
})
