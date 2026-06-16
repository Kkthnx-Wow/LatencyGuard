local _, ns = ...
if GetLocale() ~= "deDE" then return end
local L = ns.L

L["Landing Desc Text"] = "Das %s ist eine versteckte Spieleinstellung, die die Pufferzeit für Ihre nächste Fähigkeit steuert.\n\n%s überwacht Ihren Welt-Ping in Echtzeit und passt dieses Fenster automatisch an, damit sich Ihr Gameplay reaktionsschnell anfühlt, ohne die Fähigkeit zu verlieren, Zauber effektiv in die Warteschlange zu stellen. Hohe Latenz erfordert ein breiteres Warteschlangenfenster, während niedrige Latenz von einem engeren Fenster profitiert.\n\nErweitern Sie das LatencyGuard-Menü links und öffnen Sie Allgemein, um Toleranz und Feedback zu konfigurieren."

L["Automate Spell Queue Window"] = "Zauberwarteschlangen-Fenster automatisieren"
L["Automate Spell Queue Window Tooltip"] = "Wenn aktiviert, übernimmt LatencyGuard alle Anpassungen der Zauberwarteschlange.\n\n|cffff0000Hinweis:|r Die Deaktivierung stoppt alle Updates sofort."
L["Enable Chat Feedback"] = "Chat-Feedback aktivieren"
L["Enable Chat Feedback Tooltip"] = "Gibt eine Nachricht in Ihrem Chatlog aus, wenn das Zauberwarteschlangen-Fenster mit einem neuen Zielwert aktualisiert wird."
L["Tolerance Buffer"] = "Toleranzpuffer"
L["Tolerance Buffer Tooltip"] = "Dieser Wert wird Ihrem aktuellen Welt-Ping hinzugefügt.\n\nHohe Werte (200+) sind sicherer für Verbindungen mit hoher Latenz.\nNiedrige Werte (50-100) sind besser für kompetitives Spielen auf hohem Niveau."

L["Init Message"] = "v%s initialisiert. Verwenden Sie |cFFFFD700/lg|r zum Konfigurieren."
L["Update Message"] = "SQW auf |cFFFFD700%dms|r gesetzt (Ping: %d + Puffer: %d)"
