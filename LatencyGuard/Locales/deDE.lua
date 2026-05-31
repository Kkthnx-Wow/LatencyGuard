local ADDON_NAME, NS = ...
if GetLocale() ~= "deDE" then return end
local L = NS.L

L["Config_Author"] = "Erstellt von %s%s|r"
L["Config_DescTitle"] = "Warum gibt es dieses Addon?"
L["Config_DescText"] = "Das %sZauberwarteschlangen-Fenster|r ist eine versteckte Spieleinstellung, die die 'Pufferzeit' für Ihre nächste Fähigkeit steuert.\n\n%sLatencyGuard|r überwacht Ihren Welt-Ping in Echtzeit und passt dieses Fenster automatisch an, damit sich Ihr Gameplay reaktionsschnell anfühlt, ohne die Fähigkeit zu verlieren, Zauber effektiv in die Warteschlange zu stellen. Hohe Latenz erfordert ein breiteres Warteschlangenfenster, während niedrige Latenz von einem engeren Fenster profitiert.\n\nUm das Verhalten und die Toleranz zu konfigurieren, erweitern Sie bitte das Menü " .. ADDON_NAME .. " auf der linken Seite und wählen Sie das Optionsfeld."

L["Config_OptionsCategory"] = "Optionen"
L["Config_Enable"] = "Zauberwarteschlangen-Fenster automatisieren"
L["Config_EnableTooltip"] = "Wenn aktiviert, übernimmt das Addon alle Anpassungen der Zauberwarteschlange.\n\n%sHinweis:|r Die Deaktivierung stoppt alle Updates sofort."
L["Config_Verbose"] = "Chat-Feedback aktivieren"
L["Config_VerboseTooltip"] = "Gibt eine Nachricht in Ihrem Chatlog aus, wenn das Zauberwarteschlangen-Fenster mit einem neuen Zielwert aktualisiert wird."
L["Config_Tolerance"] = "Toleranzpuffer"
L["Config_ToleranceTooltip"] = "Dieser Wert wird Ihrem aktuellen Welt-Ping hinzugefügt.\n\nHohe Werte (200+) sind sicherer für Verbindungen mit hoher Latenz.\nNiedrige Werte (50-100) sind besser für kompetitives Spielen auf hohem Niveau."

L["Core_InitMessage"] = "v%s Initialisiert. Verwenden Sie |cFFFFD700/lg|r zum Konfigurieren."
L["Logic_UpdateMessage"] = "SQW auf |cFFFFD700%dms|r gesetzt (Ping: %d + Puffer: %d)"
