local ADDON_NAME, NS = ...
NS.L = setmetatable({}, { __index = function(t, k) return k end })
local L = NS.L

-- Config Info Panel
L["Config_Title"] = ADDON_NAME .. " %s"
L["Config_Author"] = "Created by %s%s|r"
L["Config_DescTitle"] = "Why does this addon exist?"
L["Config_DescText"] = "The %sSpell Queue Window|r is a hidden game setting that controls the 'buffer time' for your next ability.\n\n%sLatencyGuard|r monitors your real-time world ping and adjusts this window automatically so your gameplay feels snappy without losing the ability to queue spells effectively. High latency requires a wider queue window, while low latency benefits from a tighter window.\n\nTo configure the behavior and tolerance, please expand the " .. ADDON_NAME .. " menu on the left and select the Options panel."

-- Config Options
L["Config_OptionsCategory"] = "Options"
L["Config_Enable"] = "Automate Spell Queue Window"
L["Config_EnableTooltip"] = "If checked, the addon will handle all Spell Queue adjustments.\n\n%sNote:|r Disabling this stops all updates immediately."
L["Config_Verbose"] = "Enable Chat Feedback"
L["Config_VerboseTooltip"] = "Prints a message in your chat log whenever the Spell Queue Window is updated with a new target value."
L["Config_Tolerance"] = "Tolerance Buffer"
L["Config_ToleranceTooltip"] = "This value is added to your current world ping.\n\nHigh values (200+) are safer for high-latency connections.\nLow values (50-100) are better for high-end competitive play."

-- Chat Messages
L["Core_InitMessage"] = "v%s Initialized. Use |cFFFFD700/lg|r to configure."
L["Logic_UpdateMessage"] = "SQW set to |cFFFFD700%dms|r (Ping: %d + Buffer: %d)"
