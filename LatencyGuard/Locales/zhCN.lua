local ADDON_NAME, NS = ...
if GetLocale() ~= "zhCN" then return end
local L = NS.L

L["Config_Author"] = "由 %s%s|r 创建"
L["Config_DescTitle"] = "为什么会有这个插件？"
L["Config_DescText"] = "%s法术队列窗口|r 是一项隐藏的游戏设置，它控制着你下一个技能的“缓冲时间”。\n\n%sLatencyGuard|r 会实时监控你的世界延迟，并自动调整该窗口，从而让你的操作感觉更加灵敏，同时又不会失去有效排队法术的能力。高延迟需要更宽的队列窗口，而低延迟则受益于更窄的窗口。\n\n若要配置其行为和容差，请展开左侧的 " .. ADDON_NAME .. " 菜单，并选择“选项”面板。"

L["Config_OptionsCategory"] = "选项"
L["Config_Enable"] = "自动调整法术队列窗口"
L["Config_EnableTooltip"] = "如果勾选，插件将处理所有法术队列的调整。\n\n%s注意：|r 取消勾选会立即停止所有更新。"
L["Config_Verbose"] = "启用聊天反馈"
L["Config_VerboseTooltip"] = "每当法术队列窗口更新为新目标值时，在你的聊天记录中打印一条消息。"
L["Config_Tolerance"] = "容差缓冲"
L["Config_ToleranceTooltip"] = "此数值会添加到你当前的世界延迟中。\n\n高数值（200+）对于高延迟连接更安全。\n低数值（50-100）更适合高端竞技游戏。"

L["Core_InitMessage"] = "v%s 已初始化。使用 |cFFFFD700/lg|r 进行配置。"
L["Logic_UpdateMessage"] = "SQW 已设置为 |cFFFFD700%dms|r (延迟: %d + 缓冲: %d)"
