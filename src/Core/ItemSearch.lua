local _, PIS = ...

local Search = {}
PIS.Search = Search

-- The item database ships as a few large string chunks of
-- "iconFileID:Item Name<TAB>search tags" lines (see src\Data\ItemIcons.lua).
-- Searching the raw string keeps load time and memory far below what 80k+
-- table entries would cost.
local blob, blobLower

local function EnsureLoaded()
	if blob then
		return
	end

	blob = table.concat(PIS.ItemIconData, "\n")
	PIS.ItemIconData = nil

	-- string.lower only folds ASCII bytes, so byte offsets in blobLower always
	-- line up with blob, including for multi-byte UTF-8 names.
	blobLower = blob:lower()
end

-- Returns an array of { icon = fileID, name = itemName } for items matching
-- every whitespace-separated word of the query (case-insensitive, any order),
-- against the item name plus its slot/type tags ("cloth shoulder", "sword").
-- One entry per distinct icon, in alphabetical order.
function Search:Find(query, maxResults)
	EnsureLoaded()

	local tokens = {}
	for token in query:lower():gmatch("%S+") do
		tokens[#tokens + 1] = token
	end
	if #tokens == 0 then
		return {}
	end

	-- Scan the blob for the longest token (fewest candidate lines), then
	-- check the remaining tokens per line.
	local primary = tokens[1]
	for _, token in ipairs(tokens) do
		if #token > #primary then
			primary = token
		end
	end

	local results = {}
	local seen = {}
	local init = 1

	while #results < maxResults do
		local matchStart = blobLower:find(primary, init, true)
		if not matchStart then
			break
		end

		local lineEnd = blobLower:find("\n", matchStart, true) or (#blobLower + 1)
		local lineStart = matchStart
		while lineStart > 1 and blob:byte(lineStart - 1) ~= 10 do
			lineStart = lineStart - 1
		end

		local lineLower = blobLower:sub(lineStart, lineEnd - 1)
		local sep = lineLower:find(":", 1, true)
		if sep then
			-- Match against name + tags, never the icon fileID digits
			local haystack = lineLower:sub(sep + 1)
			local allMatch = true
			for _, token in ipairs(tokens) do
				if not haystack:find(token, 1, true) then
					allMatch = false
					break
				end
			end

			if allMatch then
				local line = blob:sub(lineStart, lineEnd - 1)
				local icon, name = line:match("^(%d+):([^\t]*)")
				icon = icon and tonumber(icon)
				if icon and not seen[icon] then
					seen[icon] = true
					results[#results + 1] = { icon = icon, name = name }
				end
			end
		end

		init = lineEnd + 1
	end

	return results
end
