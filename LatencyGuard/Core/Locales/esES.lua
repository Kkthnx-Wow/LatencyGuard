local _, ns = ...
if GetLocale() ~= "esES" then return end
local L = ns.L

L["Landing Desc Text"] = "La %s es un ajuste oculto del juego que controla el tiempo de búfer para tu próxima habilidad.\n\n%s monitorea tu ping mundial en tiempo real y ajusta esta ventana automáticamente para que tu juego se sienta rápido sin perder la capacidad de poner hechizos en cola de manera efectiva. La alta latencia requiere una ventana de cola más amplia, mientras que la baja latencia se beneficia de una ventana más ajustada.\n\nExpande el menú LatencyGuard a la izquierda y abre General para configurar la tolerancia y la retroalimentación."

L["Automate Spell Queue Window"] = "Automatizar la Ventana de Cola de Hechizos"
L["Automate Spell Queue Window Tooltip"] = "Si está marcado, el addon manejará todos los ajustes de la Cola de Hechizos.\n\n|cffff0000Nota:|r Desactivar esto detiene todas las actualizaciones de inmediato."
L["Enable Chat Feedback"] = "Habilitar retroalimentación en el chat"
L["Enable Chat Feedback Tooltip"] = "Imprime un mensaje en tu registro de chat cada vez que la Ventana de Cola de Hechizos se actualiza con un nuevo valor objetivo."
L["Tolerance Buffer"] = "Búfer de Tolerancia"
L["Tolerance Buffer Tooltip"] = "Este valor se suma a tu ping mundial actual.\n\nLos valores altos (200+) son más seguros para conexiones de alta latencia.\nLos valores bajos (50-100) son mejores para el juego competitivo de alto nivel."

L["Init Message"] = "v%s inicializado. Usa %s para configurar."
L["Update Message"] = "SQW establecido en |cFFFFD700%dms|r (Ping: %d + Búfer: %d)"
