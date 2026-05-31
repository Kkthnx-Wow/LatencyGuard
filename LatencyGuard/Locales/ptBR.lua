local ADDON_NAME, NS = ...
if GetLocale() ~= "ptBR" then return end
local L = NS.L

L["Config_Author"] = "Criado por %s%s|r"
L["Config_DescTitle"] = "Por que este addon existe?"
L["Config_DescText"] = "A %sJanela de Fila de Feitiços|r é uma configuração oculta do jogo que controla o 'tempo de buffer' para sua próxima habilidade.\n\n%sLatencyGuard|r monitora o seu ping mundial em tempo real e ajusta esta janela automaticamente para que a sua jogabilidade pareça responsiva sem perder a capacidade de colocar feitiços na fila de forma eficaz. A alta latência requer uma janela de fila mais ampla, enquanto a baixa latência se beneficia de uma janela mais estreita.\n\nPara configurar o comportamento e a tolerância, expanda o menu " .. ADDON_NAME .. " à esquerda e selecione o painel de Opções."

L["Config_OptionsCategory"] = "Opções"
L["Config_Enable"] = "Automatizar Janela de Fila de Feitiços"
L["Config_EnableTooltip"] = "Se marcado, o addon lidará com todos os ajustes da Fila de Feitiços.\n\n%sNota:|r Desativar isso interrompe todas as atualizações imediatamente."
L["Config_Verbose"] = "Ativar Feedback no Chat"
L["Config_VerboseTooltip"] = "Imprime uma mensagem em seu registro de chat sempre que a Janela de Fila de Feitiços é atualizada com um novo valor alvo."
L["Config_Tolerance"] = "Buffer de Tolerância"
L["Config_ToleranceTooltip"] = "Este valor é adicionado ao seu ping mundial atual.\n\nValores altos (200+) são mais seguros para conexões de alta latência.\nValores baixos (50-100) são melhores para jogabilidade competitiva de alto nível."

L["Core_InitMessage"] = "v%s Inicializado. Use |cFFFFD700/lg|r para configurar."
L["Logic_UpdateMessage"] = "SQW definido para |cFFFFD700%dms|r (Ping: %d + Buffer: %d)"
