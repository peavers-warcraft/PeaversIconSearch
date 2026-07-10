local _, PIS = ...

local Search = {}
PIS.Search = Search

-- The item database ships with PeaversIconSearchData as a few large string
-- chunks of "iconFileID:Item Name<TAB>search tags" lines, refreshed daily.
-- Searching the raw string keeps load time and memory far below what 80k+
-- table entries would cost.
local blob, blobLower

local function EnsureLoaded()
	if blob then
		return
	end

	local data = _G.PeaversIconSearchData
	blob = table.concat(data.API.TakeItemIconData(), "\n")

	-- string.lower only folds ASCII bytes, so byte offsets in blobLower always
	-- line up with blob, including for multi-byte UTF-8 names.
	blobLower = blob:lower()
end

-- Every query token must appear in the name+tags; at least one type tag (if
-- any are given) must hit a whole word in the tag section.
local function LineMatches(haystack, tokens, typeTags)
	for _, token in ipairs(tokens) do
		if not haystack:find(token, 1, true) then
			return false
		end
	end

	if typeTags then
		local tagStart = haystack:find("\t", 1, true)
		local tags = " " .. (tagStart and haystack:sub(tagStart + 1) or "") .. " "
		for _, tag in ipairs(typeTags) do
			if tags:find(" " .. tag .. " ", 1, true) then
				return true
			end
		end
		return false
	end

	return true
end

-- Scan the blob for one needle, appending matching lines' icons to results
local function Scan(needle, tokens, typeTags, results, seen, maxResults)
	local init = 1

	while #results < maxResults do
		local matchStart = blobLower:find(needle, init, true)
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
		-- Match against name + tags, never the icon fileID digits
		if sep and LineMatches(lineLower:sub(sep + 1), tokens, typeTags) then
			local line = blob:sub(lineStart, lineEnd - 1)
			local icon, name = line:match("^(%d+):([^\t]*)")
			icon = icon and tonumber(icon)
			if icon and not seen[icon] then
				seen[icon] = true
				results[#results + 1] = { icon = icon, name = name }
			end
		end

		init = lineEnd + 1
	end
end

-- Returns an array of { icon = fileID, name = itemName } for items matching
-- every whitespace-separated word of the query (case-insensitive, any order),
-- against the item name plus its slot/type tags ("cloth shoulder", "sword").
-- typeTags is an optional array of exact tag words (e.g. {"shoulder","dagger"});
-- an item matches if it carries ANY of them. One entry per distinct icon, in
-- alphabetical order.
function Search:Find(query, typeTags, maxResults)
	EnsureLoaded()

	local tokens = {}
	for token in query:lower():gmatch("%S+") do
		tokens[#tokens + 1] = token
	end

	if typeTags and #typeTags == 0 then
		typeTags = nil
	end
	if #tokens == 0 and not typeTags then
		return {}
	end

	local results = {}
	local seen = {}

	if #tokens > 0 then
		-- One scan for the longest token (fewest candidate lines); results
		-- come out in data order, which is alphabetical.
		local primary = tokens[1]
		for _, token in ipairs(tokens) do
			if #token > #primary then
				primary = token
			end
		end
		Scan(primary, tokens, typeTags, results, seen, maxResults)
	else
		-- Type filter only: one scan per selected tag, then restore
		-- alphabetical order across the merged results.
		for _, tag in ipairs(typeTags) do
			Scan(tag, tokens, typeTags, results, seen, maxResults)
		end
		table.sort(results, function(a, b)
			return a.name:lower() < b.name:lower()
		end)
	end

	return results
end
