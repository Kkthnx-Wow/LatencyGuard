local ADDON_NAME, NS = ...
if GetLocale() ~= "esMX" then return end
local L = NS.L

L["Config_Author"] = "Creado por %s%s|r"
L["Config_DescTitle"] = "¿Por qué existe este addon?"
L["Config_DescText"] = "La %sVentana de Cola de Hechizos|r es un ajuste oculto del juego que controla el 'tiempo de búfer' para tu próxima habilidad.\n\n%sLatencyGuard|r monitorea tu ping mundial en tiempo real y ajusta esta ventana automáticamente para que tu juego se sienta rápido sin perder la capacidad de poner hechizos en cola de manera efectiva. La alta latencia requiere una ventana de cola más amplia, mientras que la baja latencia se beneficia de una ventana más ajustada.\n\nPara configurar el comportamiento y la tolerancia, expanda el menú de " .. ADDON_NAME .. " a la izquierda y seleccione el panel de Opciones."

L["Config_OptionsCategory"] = "Opciones"
L["Config_Enable"] = "Automatizar la Ventana de Cola de Hechizos"
L["Config_EnableTooltip"] = "Si está marcado, el addon manejará todos los ajustes de la Cola de Hechizos.\n\n%sNota:|r Desactivar esto detiene todas las actualizaciones de inmediato."
L["Config_Verbose"] = "Habilitar retroalimentación en el chat"
L["Config_VerboseTooltip"] = "Imprime un mensaje en tu registro de chat cada vez que la Ventana de Cola de Hechizos se actualiza con un nuevo valor objetivo."
L["Config_Tolerance"] = "Búfer de Tolerancia"
L["Config_ToleranceTooltip"] = "Este valor se suma a tu ping mundial actual.\n\nLos valores altos (200+) son más seguros para conexiones de alta latencia.\nLos valores bajos (50-100) son mejores para el juego competitivo de alto nivel."

L["Core_InitMessage"] = "v%s Inicializado. Usa |cFFFFD700/lg|r para configurar."
L["Logic_UpdateMessage"] = "SQW establecido en |cFFFFD700%dms|r (Ping: %d + Búfer: %d)"
