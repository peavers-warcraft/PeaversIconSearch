local _, PIS = ...

local ConfigUI = {}
PIS.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons

-- The addon has no settings: it attaches to Blizzard's icon picker and stores
-- nothing. Its PeaversConfig presence is a single Information page explaining
-- where the search lives and how it behaves.
function ConfigUI:BuildInfoPage(parentFrame)
    PeaversCommons.ConfigUIUtils.BuildInfoPage(parentFrame, "Icon Search", {
        "Adds an item search box to the transmog outfit icon picker, so you " ..
            "can find the right icon by naming the item it belongs to instead " ..
            "of scrolling through thousands of icons.",

        { header = "Where to find it" },
        "Open the transmog interface and save an outfit. In the icon picker " ..
            "popup, a small filter funnel button sits next to the icon type " ..
            "dropdown - it glows gold while a search or filter is active.",

        { header = "Searching" },
        "Click the funnel and type at least two letters of an item's name - " ..
            "the icon grid narrows to matching items as you type. You can also " ..
            "filter by item type, from helmets down to warglaives, or combine " ..
            "both. Clearing the search restores Blizzard's full grid.",

        { header = "Where the data comes from" },
        "The item-name-to-icon index ships in the PeaversIconSearchData " ..
            "companion addon, updated daily from wago.tools game-data exports.",
    })
end

function ConfigUI:GetPages()
    return {
        { key = "info", label = "Information", builder = function(f) ConfigUI:BuildInfoPage(f) end },
    }
end

return ConfigUI
