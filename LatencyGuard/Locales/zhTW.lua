local ADDON_NAME, NS = ...
if GetLocale() ~= "zhTW" then return end
local L = NS.L

L["Config_Author"] = "由 %s%s|r 建立"
L["Config_DescTitle"] = "為什麼會有這個插件？"
L["Config_DescText"] = "%s法術佇列視窗|r 是一項隱藏的遊戲設定，它控制著你下一個技能的「緩衝時間」。\n\n%sLatencyGuard|r 會即時監控你的世界延遲，並自動調整該視窗，從而讓你的操作感覺更加靈敏，同時又不會失去有效排隊法術的能力。高延遲需要更寬的佇列視窗，而低延遲則受益於更窄的視窗。\n\n若要設定其行為和容差，請展開左側的 " .. ADDON_NAME .. " 選單，並選擇「選項」面板。"

L["Config_OptionsCategory"] = "選項"
L["Config_Enable"] = "自動調整法術佇列視窗"
L["Config_EnableTooltip"] = "如果勾選，插件將處理所有法術佇列的調整。\n\n%s注意：|r 取消勾選會立即停止所有更新。"
L["Config_Verbose"] = "啟用聊天回饋"
L["Config_VerboseTooltip"] = "每當法術佇列視窗更新為新目標值時，在你的聊天紀錄中列印一條訊息。"
L["Config_Tolerance"] = "容差緩衝"
L["Config_ToleranceTooltip"] = "此數值會加入到你目前的世界延遲中。\n\n高數值（200+）對於高延遲連線更安全。\n低數值（50-100）更適合高階競技遊戲。"

L["Core_InitMessage"] = "v%s 已初始化。使用 |cFFFFD700/lg|r 進行設定。"
L["Logic_UpdateMessage"] = "SQW 已設定為 |cFFFFD700%dms|r (延遲: %d + 緩衝: %d)"
