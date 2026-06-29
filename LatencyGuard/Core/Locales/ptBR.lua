local _, ns = ...
if GetLocale() ~= "ptBR" then return end
local L = ns.L

L["Landing Desc Text"] = "A %s é uma configuração oculta do jogo que controla o tempo de buffer para sua próxima habilidade.\n\n%s monitora o seu ping mundial em tempo real e ajusta esta janela automaticamente para que a sua jogabilidade pareça responsiva sem perder a capacidade de colocar feitiços na fila de forma eficaz. A alta latência requer uma janela de fila mais ampla, enquanto a baixa latência se beneficia de uma janela mais estreita.\n\nExpanda o menu LatencyGuard à esquerda e abra Geral para configurar tolerância e feedback."

L["Automate Spell Queue Window"] = "Automatizar Janela de Fila de Feitiços"
L["Automate Spell Queue Window Tooltip"] = "Se marcado, o addon lidará com todos os ajustes da Fila de Feitiços.\n\n|cffff0000Nota:|r Desativar isso interrompe todas as atualizações imediatamente."
L["Enable Chat Feedback"] = "Ativar Feedback no Chat"
L["Enable Chat Feedback Tooltip"] = "Imprime uma mensagem em seu registro de chat sempre que a Janela de Fila de Feitiços é atualizada com um novo valor alvo."
L["Tolerance Buffer"] = "Buffer de Tolerância"
L["Tolerance Buffer Tooltip"] = "Este valor é adicionado ao seu ping mundial atual.\n\nValores altos (200+) são mais seguros para conexões de alta latência.\nValores baixos (50-100) são melhores para jogabilidade competitiva de alto nível."

L["Init Message"] = "v%s inicializado. Use %s para configurar."
L["Update Message"] = "SQW definido para |cFFFFD700%dms|r (Ping: %d + Buffer: %d)"
