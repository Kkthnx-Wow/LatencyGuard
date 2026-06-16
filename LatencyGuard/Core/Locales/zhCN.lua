local _, ns = ...
if GetLocale() ~= "zhCN" then return end
local L = ns.L

L["Landing Desc Text"] = "%s是一项隐藏的游戏设置，它控制着你下一个技能的缓冲时间。\n\n%s会实时监控你的世界延迟，并自动调整该窗口，从而让你的操作感觉更加灵敏，同时又不会失去有效排队法术的能力。高延迟需要更宽的队列窗口，而低延迟则受益于更窄的窗口。\n\n展开左侧的 LatencyGuard 菜单并打开“常规”以配置容差和反馈。"

L["Automate Spell Queue Window"] = "自动调整法术队列窗口"
L["Automate Spell Queue Window Tooltip"] = "如果勾选，插件将处理所有法术队列的调整。\n\n|cffff0000注意：|r 取消勾选会立即停止所有更新。"
L["Enable Chat Feedback"] = "启用聊天反馈"
L["Enable Chat Feedback Tooltip"] = "每当法术队列窗口更新为新目标值时，在你的聊天记录中打印一条消息。"
L["Tolerance Buffer"] = "容差缓冲"
L["Tolerance Buffer Tooltip"] = "此数值会添加到你当前的世界延迟中。\n\n高数值（200+）对于高延迟连接更安全。\n低数值（50-100）更适合高端竞技游戏。"

L["Init Message"] = "v%s 已初始化。使用 |cFFFFD700/lg|r 进行配置。"
L["Update Message"] = "SQW 已设置为 |cFFFFD700%dms|r (延迟: %d + 缓冲: %d)"
