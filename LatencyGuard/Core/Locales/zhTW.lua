local _, ns = ...
if GetLocale() ~= "zhTW" then return end
local L = ns.L

L["Landing Desc Text"] = "%s是一項隱藏的遊戲設定，它控制著你下一個技能的緩衝時間。\n\n%s會即時監控你的世界延遲，並自動調整該視窗，從而讓你的操作感覺更加靈敏，同時又不會失去有效排隊法術的能力。高延遲需要更寬的佇列視窗，而低延遲則受益於更窄的視窗。\n\n展開左側的 LatencyGuard 選單並開啟「一般」以設定容差和回饋。"

L["Automate Spell Queue Window"] = "自動調整法術佇列視窗"
L["Automate Spell Queue Window Tooltip"] = "如果勾選，插件將處理所有法術佇列的調整。\n\n|cffff0000注意：|r 取消勾選會立即停止所有更新。"
L["Enable Chat Feedback"] = "啟用聊天回饋"
L["Enable Chat Feedback Tooltip"] = "每當法術佇列視窗更新為新目標值時，在你的聊天紀錄中列印一條訊息。"
L["Tolerance Buffer"] = "容差緩衝"
L["Tolerance Buffer Tooltip"] = "此數值會加入到你目前的世界延遲中。\n\n高數值（200+）對於高延遲連線更安全。\n低數值（50-100）更適合高階競技遊戲。"

L["Init Message"] = "v%s 已初始化。使用 %s 進行設定。"
L["Update Message"] = "SQW 已設定為 |cFFFFD700%dms|r (延遲: %d + 緩衝: %d)"
